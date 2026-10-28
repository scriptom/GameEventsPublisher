# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`GameEventsPublisher` is an Unreal Tournament 1999 (UnrealScript) mutator package. It POSTs match events (`WaitingPlayers`, `MatchStarted`, `FlagCapture`, `MatchEnded`, ...) as JSON to an HTTP host configured in the game's ini. `Classes/` holds the package sources. `simple-server/` is a Node receiver that logs incoming events for manual testing.

This repo is not the build environment. It lives inside the UT99 install (the parent folder, `UnrealTournament/`). The compiled package (`System/GameEventsPublisher.u`) and the live config are in that install, not here.

## Build

- Compile from the install's `System/` folder with `UCC.exe make`. The package is listed in `EditPackages` (`System/UnrealTournament.ini:650`) and built from `<install>/GameEventsPublisher/Classes/`.
- Delete `System/GameEventsPublisher.u` before compiling. `UCC.exe make` skips a package whose `.u` already exists and still reports success, so the build changes nothing.
- Check `System/ucc.log` for `Success - 0 error(s), 0 warnings`, and for a `Success: Compiled N line(s)` line for `GameEventsPublisher`. A run that compiled nothing has no such line.
- Restart the server after rebuilding so the new package is loaded.

## Run and test

- There is no automated test suite. The `test` script in `simple-server/package.json` is a placeholder.
- Manual loop: `npm start` in `simple-server/` (listens on `$PORT`, default 3000, route `POST /handle-event`). Run a UT99 server with the mutator enabled. The raw request, headers and JSON body are printed to the console.
- The install's ini overrides the code defaults: `[GameEventsPublisher.GameEventsConfig]` in `System/UnrealTournament.ini:5251` sets `Port=3000`, `Path=handle-event`, `Debug=True`. The repo default is port 7790.
- To verify one event type, trigger it in a game and check the `simple-server` output. The repo does not document how to launch the dedicated server.
- The mod logs with the `++ [GameEventsPublisher]` prefix.

## Architecture

**Loading.** `System/UnrealTournament.ini:82` lists `GameEventsPublisherSA` under `[Engine.GameEngine]` as a ServerActor. Its `PostBeginPlay` adds `GameEventsMutator` to the game's mutator chain and destroys itself. A separate `MutatorList` entry in `[UTMenu.UTMenuBotmatchCW]` (`:4277`) applies only to the menu's botmatch preset.

**Mutator and manager.** `GameEventsMutator.PreBeginPlay` reads `GameEventsConfig`, which is `globalconfig`, and calls `SaveConfig()`. It then spawns `GameEventsManager` with tag `'EndGame'` and a `GameEventsMessagingSpectator` owned by the manager. The manager's `Setup` spawns `MatchStartTimedTrigger` on the `'MatchStart'` event.

**Event sources.** The manager is driven by three things:
- The game's end-of-match path. `GameInfo.EndGame` fires every actor with tag `'EndGame'`, which is how the manager reaches `MatchEnded`.
- `MatchStartTimedTrigger` on the `'MatchStart'` event, which moves the manager to `MatchStarted`.
- The `WaitingPlayers` state's timer, which publishes periodically and then sends `WaitingPlayersEnd` once `WaitingPlayersIntervalInSecsExpired` is reached.

Flag captures come from `GameEventsMessagingSpectator`. It receives the game's `CTFMessage` broadcasts, and switch `0` (a capture) calls `GameEventsManager.FlagCapture`.

**Publishing.** `Publish(eventName, instigatorId)` takes a snapshot in `GameEventArgs.Create` (reads the level, game, replication info and pawns), then serialises it with `ConvertToJson`. The per-team and per-player JSON shapes come from the `TeamInfoJson` and `PlayerInfoJson` templates in the config, using `%Token%` substitution through `GameEventsPublisherHelper.Replace`.

**Transport.** Each `Publish` spawns a new `GameEventsPublisherSubmitter`, a `UBrowserBufferedTCPLink` from the UBrowser package. This is the behaviour on `fix/end-capture-race-condition`. On `main` a single submitter is shared, which lets a second event overwrite the first before it is sent. The submitter resolves the host, binds a port and opens a TCP connection. On `Opened` it writes an HTTP/1.0 POST with `Connection: close`. It then reads the response, and on a `200` substring it moves to `Submitted`. It destroys itself when the link closes or fails. Data is only written in `Tick`, via `DoBufferQueueIO`. `PostBeginPlay` also calls `Disable('Tick')`. Sending still works with that line in place, and I could not explain why from the source, so leave it alone unless you test the change.

**Dependencies outside this repo.** `Mutator`, `DeathMatchPlus`, `TeamGamePlus`, `CTFGame`, `MessagingSpectator`, `TimedTrigger` and `UBrowserBufferedTCPLink` come from the UT99 source tree. The workspace file points to it at `../../../../development/UT99` relative to this repo, which is `/mnt/c/Users/tomas/development/UT99`. Read those sources when a change depends on game behaviour.

## Conventions

- All `.uc` files use CRLF line endings. Keep them when editing.
- Indentation is mixed. `GameEventsMutator` and `GameEventsManager` use 4 spaces. `GameEventsPublisherSubmitter` uses 2 spaces. Match the file you are in.
- Do not commit build output (`.u`, `.int`) from the install. It is outside this repo.
