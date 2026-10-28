const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

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

  res.sendStatus(200);
});

app.listen(port, () => {
  console.log(`Listening on http://localhost:${port}`);
});
