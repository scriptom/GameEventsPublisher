const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

// Lists a parsed name's code points, to see exactly what the receiver got.
function describeName(name) {
  return [...name].map((c) => `U+${c.codePointAt(0).toString(16).toUpperCase().padStart(4, '0')}`);
}

function logPlayers(body) {
  let event;
  try {
    event = JSON.parse(body.toString('utf8'));
  } catch (err) {
    console.log(`[parsed] INVALID JSON: ${err.message}`);
    return;
  }

  const players = Array.isArray(event.Players) ? event.Players : [];
  console.log(`[parsed] ${event.Name} - ${players.length} player(s)`);
  for (const p of players) {
    const name = String(p.Name);
    const codePoints = describeName(name);
    console.log(`[parsed]   #${p.Id} name=${JSON.stringify(name)} (${codePoints.length} chars)`);
    console.log(`[parsed]     code points: ${codePoints.join(' ')}`);
  }
}

// Keep the body as an untouched Buffer for any Content-Type so it can be logged as-is.
app.post('/handle-event', express.raw({ type: () => true }), (req, res) => {
  const body = Buffer.isBuffer(req.body) ? req.body : Buffer.alloc(0);

  console.log(`--- ${new Date().toISOString()} ---`);
  console.log(`${req.method} ${req.originalUrl} HTTP/${req.httpVersion}`);
  for (let i = 0; i < req.rawHeaders.length; i += 2) {
    console.log(`${req.rawHeaders[i]}: ${req.rawHeaders[i + 1]}`);
  }
  console.log('');
  console.log(body.toString('utf8'));
  console.log('');
  logPlayers(body);
  console.log('');

  res.sendStatus(200);
});

app.listen(port, () => {
  console.log(`Listening on http://localhost:${port}`);
});
