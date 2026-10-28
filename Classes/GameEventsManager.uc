class GameEventsManager extends Actor;

var GameEventsConfig Config;
var class<GameEventsPublisherHelper> Helper;
var MatchStartTimedTrigger StartMatchTrigger;
var bool bOvertimeStarted;

function Setup(GameEventsConfig configuration) {
    Config = configuration;
    Helper = class'GameEventsPublisherHelper';
    StartMatchTrigger = Level.Spawn(class'MatchStartTimedTrigger', Self, 'MatchStart');
}

function StartMatch() {
    GotoState('MatchStarted');
}

function FlagCapture(PlayerReplicationInfo scorerPRI, CTFFlag flag) {
    Publish('FlagCapture', scorerPRI.PlayerId);
}

// The game can end tied more than once in sudden death, so publish only the first
function OvertimeStarted() {
    if (bOvertimeStarted) {
        return;
    }
    bOvertimeStarted = true;
    Publish('OvertimeStarted', -1);
}

function Trigger(Actor Other, Pawn EventInstigator) {
    if (Other == Level.Game) {
        LogInternal(Self$"(Other.Name="$Other.Name$") by "$EventInstigator.Name);
        GotoState('MatchEnded');
    }
    else {
        LogInternal(Self@"Got Trigger of: "$Other.Name@"by"@EventInstigator.Name);
    }
    super.Trigger(Other, EventInstigator);
}

function LogInternal(String text) {
    Log("++ [GameEventsPublisher]"@text, 'GameEventsManager');
}

function Publish(Name eventName, int instigatorId) {
    local GameEventArgs arg;
    local GameEventsPublisherSubmitter submitter;

    LogInternal("GameEventsManager.Publish(eventName="$eventName$")");
    arg = class'GameEventArgs'.static.Create(Level, eventName, instigatorId);
    class'GameEventArgs'.static.PrintPlayers(arg);
    // One submitter per event, so a publish can't overwrite one still in flight.
    submitter = Level.Spawn(class'GameEventsPublisherSubmitter');
    submitter.OpenAndSend(Config.Host, Config.Port, Config.Path, Config.PasswordHeaderName, Config.Password, arg.ConvertToJson(Config.TeamInfoJson, Config.PlayerInfoJson), Config.Debug);
}

// function Timer() {
//     PrintCurrentInformation();
// }

// States
auto state WaitingPlayers {

    function Timer() {
        if (Level.TimeSeconds < Config.WaitingPlayersIntervalInSecsExpired)
        {
            Publish(GetStateName(), -1);
        }
        else
        {
            Publish('WaitingPlayersEnd', -1);
            LogInternal("GameEventsManager.WaitingPlayersExpired("$Config.WaitingPlayersIntervalInSecsExpired$")");
            Disable('Timer');
        }
    }

Begin:
    Publish(GetStateName(), -1);
    // SetTimer(Config.WaitingPlayersDuration, false);
    SetTimer(Config.WaitingPlayersIntervalInSecs, true);
}

state MatchStarted {

Begin:
    Publish('MatchStarted', -1);
}

state MatchEnded {

Begin:
    Publish('MatchEnded', -1);
}
// EOF States

// Debug
function PrintCurrentInformation() {
    local int i;
    local GameEventArgs arg;

    arg = class'GameEventArgs'.static.Create(Level, GetStateName(), -1);
    Log("GlobalTimer => NetWait: "$(DeathMatchPlus(Level.Game).NetWait));
    Log("GlobalTimer => ElapsedTime: "$DeathMatchPlus(Level.Game).ElapsedTime);
    Log("GlobalTimer => TimeSeconds: "$Level.TimeSeconds);
    Log("GlobalTimer => CountDown: "$DeathMatchPlus(Level.Game).CountDown);
    Log("GlobalTimer => CountDown(default): "$DeathMatchPlus(Level.Game).default.CountDown);
    Log("GlobalTimer => bStartMatch: "$(DeathMatchPlus(Level.Game).bStartMatch));
    Log("GlobalTimer => bRequireReady: "$(DeathMatchPlus(Level.Game).bRequireReady));
    Log("GlobalTimer => bNetReady: "$(DeathMatchPlus(Level.Game).bNetReady));
    Log("GlobalTimer => RemainingTime: "$(DeathMatchPlus(Level.Game).RemainingTime));
    Log("GlobalTimer => StartTime: "$(DeathMatchPlus(Level.Game).StartTime));
    if (arg.NumPlayers > 0)
    {
        for (i = 0; i < arg.NumPlayers; i++) {
            Log("Player["$i$"] Name="$arg.GetPlayer(i).Name$"|Ready:"$arg.GetPlayer(i).Ready);
        }
    }
    else {
        Log("NO PLAYERS!");
    }
}
// EOF Debug

defaultproperties
{
      Config=None
      Helper=None
      StartMatchTrigger=None
}
