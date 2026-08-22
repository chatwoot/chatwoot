// Headless Chrome via raw CDP (no external deps). Drives the local Chromium
// binary, navigates to a URL, and prints console messages + page errors + #app.
const { spawn } = require('child_process');
const http = require('http');
const crypto = require('crypto');
const fs = require('fs');

const CHROME = 'C:\\Users\\SAMI\\AppData\\Local\\ms-playwright\\chromium-1234\\chrome-win64\\chrome.exe';
const URL = process.argv[2] || 'http://localhost:3000/';
const DIR = fs.mkdtempSync('C:\\Users\\SAMI\\AppData\\Local\\Temp\\cdp-');

function getJson(host, port, path) {
  return new Promise((res, rej) => {
    http.get({ host, port, path }, r => {
      let d = ''; r.on('data', c => (d += c));
      r.on('end', () => { try { res(JSON.parse(d)); } catch (e) { rej(e); } });
    }).on('error', rej);
  });
}

(async () => {
  const chrome = spawn(CHROME, [
    '--headless=new', '--no-sandbox', '--disable-gpu',
    '--remote-debugging-port=0', '--user-data-dir=' + DIR,
  ], { stdio: ['ignore', 'pipe', 'pipe'] });

  let port = null;
  await new Promise((res, rej) => {
    const t = setTimeout(() => rej(new Error('chrome devtools port timeout')), 15000);
    chrome.stdout.on('data', b => {
      const m = b.toString().match(/DevTools listening on ws:\/\/([\d.]+):(\d+)\//);
      if (m) { clearTimeout(t); port = +m[2]; res(); }
    });
    chrome.stderr.on('data', b => {
      const m = b.toString().match(/DevTools listening on ws:\/\/([\d.]+):(\d+)\//);
      if (m) { clearTimeout(t); port = +m[2]; res(); }
    });
  });

  const { webSocketDebuggerUrl } = await getJson('127.0.0.1', port, '/json/version');
  const wsUrl = webSocketDebuggerUrl;
  // Use the global WebSocket from Node 22+/26
  const WS = globalThis.WebSocket || require('ws');
  const ws = new WS(wsUrl);

  const pending = new Map();
  let msgId = 0;
  const send = (method, params = {}) => new Promise((res, rej) => {
    const id = ++msgId;
    pending.set(id, { res, rej });
    ws.send(JSON.stringify({ id, method, params }));
  });
  ws.on('message', d => {
    const m = JSON.parse(d.toString());
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id); pending.delete(m.id);
      m.error ? p.rej(new Error(m.error.message)) : p.res(m.result);
    }
  });
  await new Promise(r => ws.on('open', r));

  const { targetId } = await send('Target.createTarget', { url: 'about:blank' });
  const sess = await send('Target.attachToTarget', { targetId, flatten: true });
  const sid = sess.sessionId;
  const cmd = (method, params = {}) => send('Target.sendMessageToTarget', { sessionId: sid, message: JSON.stringify({ id: ++msgId, method, params }) })
    .then(r => JSON.parse(r.result).result);

  await cmd('Page.enable');
  await cmd('Runtime.enable');
  const logs = [];
  const errors = [];
  ws.on('message', d => {
    const m = JSON.parse(d.toString());
    if (m.method === 'Target.receivedMessageFromTarget') {
      const inner = JSON.parse(m.params.message);
      if (inner.method === 'Runtime.consoleAPICalled') {
        const txt = inner.params.args.map(a => a.value ?? a.description ?? a.type).join(' ');
        logs.push(`[${inner.params.type}] ${txt}`);
      }
      if (inner.method === 'Runtime.exceptionThrown') {
        const e = inner.params.exceptionDetails;
        errors.push(`EXCEPTION: ${e.exception?.description || e.text}`);
      }
    }
  });

  await cmd('Page.navigate', { url: URL });
  await new Promise(r => setTimeout(r, 6000));

  const evalRes = await cmd('Runtime.evaluate', {
    expression: `document.getElementById('app') ? document.getElementById('app').innerHTML.slice(0,400) : 'NO #app'`,
    returnByValue: true,
  });

  console.log('===== CONSOLE LOGS =====');
  console.log(logs.join('\n') || '(none)');
  console.log('\n===== PAGE ERRORS =====');
  console.log(errors.join('\n') || '(none)');
  console.log('\n===== #app innerHTML (first 400) =====');
  console.log(evalRes.result.value);

  try { fs.rmSync(DIR, { recursive: true, force: true }); } catch {}
  chrome.kill('SIGKILL');
  process.exit(0);
})().catch(e => { console.error('SCRIPT ERROR:', e.message); process.exit(1); });
