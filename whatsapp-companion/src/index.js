/**
 * HTTP server for the Chatwoot WhatsApp companion.
 *
 * Authenticated with CHATWOOT_SHARED_TOKEN (Bearer or x-companion-token header).
 * Chatwoot talks to THIS server; this server holds the WhatsApp (Baileys) socket.
 *
 * Inbound WhatsApp messages are forwarded to Chatwoot as Cloud-shaped webhooks:
 *   POST <CHATWOOT_URL>/webhooks/whatsapp_unofficial/<phone_number>
 *
 * Endpoints:
 *   GET  /health                         -> { ok: true } (container healthcheck)
 *   POST /connect                        { identifier, account_id } -> starts socket
 *   GET  /qr/:identifier                 -> 200 { qr: base64png } or 204 if connected
 *   GET  /status/:identifier             -> { status, self_number }
 *   POST /send                           { identifier, to, type, text|mediaUrl|mediaBase64, ... }
 *   GET  /media/:identifier/:mediaId     -> binary (served so Chatwoot can download it)
 *   POST /logout/:identifier             -> clears persisted auth
 */

import express from 'express';
import qrcode from 'qrcode';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { BaileysManager, STATUS, mediaPathFor } from './baileysClient.js';

const PORT = Number(process.env.PORT || 4000);
const SHARED_TOKEN = process.env.CHATWOOT_SHARED_TOKEN || '';
const CHATWOOT_URL = (process.env.CHATWOOT_URL || 'http://rails:3000').replace(/\/+$/, '');
const AUTH_DIR = process.env.AUTH_DIR || '/app/auth';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(express.json({ limit: '25mb' }));

// In-memory ring buffers for dashboard diagnostics
const EVENT_LOG = [];
const EVENT_LOG_MAX = 100;
const INBOUND_MESSAGES = [];
const INBOUND_MAX = 200;
const SSE_CLIENTS = new Set();
let LAST_FORWARD = null;

function pushLog(entry) {
  EVENT_LOG.unshift({ ts: new Date().toISOString(), ...entry });
  if (EVENT_LOG.length > EVENT_LOG_MAX) EVENT_LOG.pop();
}

function pushInbound(entry) {
  INBOUND_MESSAGES.unshift({ id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`, received_at: new Date().toISOString(), ...entry });
  if (INBOUND_MESSAGES.length > INBOUND_MAX) INBOUND_MESSAGES.pop();
  broadcastSse('inbound', INBOUND_MESSAGES[0]);
}

function broadcastSse(event, data) {
  const payload = `event: ${event}\ndata: ${JSON.stringify(data)}\n\n`;
  for (const res of SSE_CLIENTS) {
    try { res.write(payload); } catch { /* ignore */ }
  }
}

function extractInboundSummary(payload) {
  try {
    const obj = typeof payload === 'string' ? JSON.parse(payload) : payload;
    const val = obj?.entry?.[0]?.changes?.[0]?.value;
    if (!val) return null;
    if (val.messages?.[0]) {
      const m = val.messages[0];
      const c = val.contacts?.[0];
      return {
        from: m.from || c?.wa_id || '',
        pushName: c?.profile?.name || '',
        type: m.type || 'unknown',
        body: m.text?.body || m.image?.caption || m.video?.caption || m.document?.caption || m.audio ? '' : (m.text?.body || ''),
        raw: m,
        statuses: null,
      };
    }
    if (val.statuses?.[0]) {
      return { statuses: val.statuses, type: 'status' };
    }
    return null;
  } catch { return null; }
}

function listPersistedIdentifiers() {
  try {
    if (!fs.existsSync(AUTH_DIR)) return [];
    return fs.readdirSync(AUTH_DIR, { withFileTypes: true }).filter((d) => d.isDirectory()).map((d) => d.name);
  } catch {
    return [];
  }
}

const FORWARD_MAX_ATTEMPTS = 5;
const FORWARD_BASE_DELAY_MS = 1000;

async function forwardToChatwoot(identifier, body) {
  const url = `${CHATWOOT_URL}/webhooks/whatsapp_unofficial/${encodeURIComponent(identifier)}`;

  for (let attempt = 1; attempt <= FORWARD_MAX_ATTEMPTS; attempt += 1) {
    let response;
    let responseText = '';
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-companion-token': SHARED_TOKEN,
        },
        body,
      });
      responseText = await response.text().catch(() => '');
    } catch (err) {
      if (attempt < FORWARD_MAX_ATTEMPTS) {
        await delay(FORWARD_BASE_DELAY_MS * attempt);
        continue;
      }
      LAST_FORWARD = { ts: new Date().toISOString(), identifier, target_url: url, ok: false, status: 0, error: err.message, attempt };
      pushLog({ direction: 'forward-error', identifier, target_url: url, error: err.message, attempt });
      process.stderr.write(`[companion] inbound forward error for ${identifier}: ${err.message}\n`);
      return { ok: false, status: 0, error: err.message };
    }

    LAST_FORWARD = { ts: new Date().toISOString(), identifier, target_url: url, ok: response.ok, status: response.status, body: responseText.slice(0, 2000), attempt };
    if (response.ok) {
      pushLog({ direction: 'forward-ok', identifier, target_url: url, status: response.status });
      return { ok: true, status: response.status };
    }

    pushLog({ direction: 'forward-failed', identifier, target_url: url, status: response.status, body: responseText.slice(0, 2000) });
    process.stderr.write(`[companion] inbound forward failed ${response.status} for ${identifier}: ${responseText.slice(0, 500)}\n`);
    return { ok: false, status: response.status, body: responseText.slice(0, 2000) };
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const manager = new BaileysManager({
  onInbound: async (identifier, payload, _client) => {
    const body = typeof payload === 'string' ? payload : JSON.stringify(payload);
    const summary = extractInboundSummary(payload);
    const isStatus = !!(summary && summary.statuses);
    // Store inbound messages (skip status updates for inbound list, but keep in event log)
    if (!isStatus) {
      const parsed = typeof payload === 'string' ? tryParse(payload) : payload;
      const val = parsed?.entry?.[0]?.changes?.[0]?.value;
      const msg = val?.messages?.[0];
      const contact = val?.contacts?.[0];
      const meta = val?.metadata;
      // fire-and-forget Chatwoot forward, then record result
      pushLog({ direction: 'inbound', identifier, payload: parsed, summary });
      const forwardResult = await forwardToChatwoot(identifier, body);
      pushInbound({
        identifier,
        phone_number_id: meta?.phone_number_id || identifier,
        display_phone_number: meta?.display_phone_number || identifier,
        from: summary?.from || msg?.from || '',
        pushName: summary?.pushName || contact?.profile?.name || '',
        type: summary?.type || msg?.type || 'unknown',
        body: msg?.text?.body || msg?.image?.caption || msg?.video?.caption || msg?.document?.caption || msg?.text?.body || (msg?.type === 'text' ? '' : ''),
        raw_message: msg || null,
        raw_payload: parsed,
        forward: forwardResult || null,
        chatwoot_url: `${CHATWOOT_URL}/webhooks/whatsapp_unofficial/${encodeURIComponent(identifier)}`,
      });
    } else {
      pushLog({ direction: 'status', identifier, payload: typeof payload === 'string' ? tryParse(payload) : payload, summary });
      await forwardToChatwoot(identifier, body);
    }
  },
});

function tryParse(s) {
  try { return JSON.parse(s); } catch { return s; }
}

function extractToken(req) {
  const auth = req.headers['authorization'] || '';
  if (auth.startsWith('Bearer ')) return auth.slice(7);
  if (req.headers['x-companion-token']) return req.headers['x-companion-token'];
  if (req.query && req.query.token) return req.query.token;
  return null;
}

function authenticate(req, res, next) {
  if (!SHARED_TOKEN) {
    process.stderr.write('[companion] CHATWOOT_SHARED_TOKEN not configured — rejecting request\n');
    return res.status(503).json({ error: 'companion_token_not_configured', hint: 'Set CHATWOOT_SHARED_TOKEN in companion and WHATSAPP_COMPANION_TOKEN in Chatwoot' });
  }
  const token = extractToken(req);
  if (token === SHARED_TOKEN) return next();
  return res.status(401).json({ error: 'unauthorized' });
}

app.get('/health', (_req, res) => res.json({ ok: true, status: 'up' }));

// ---- Dashboard (no auth to load HTML; API calls below still require token) ----
app.get('/', (_req, res) => res.redirect('/dashboard'));
app.get('/dashboard', (_req, res) => {
  const htmlPath = path.join(__dirname, 'dashboard.html');
  if (fs.existsSync(htmlPath)) return res.sendFile(htmlPath);
  return res.status(404).send('dashboard.html not found');
});

// ---- Admin API (authenticated) ----
app.get('/admin/api/health', authenticate, (_req, res) => {
  const persisted = listPersistedIdentifiers();
  const live = [...manager.clients.entries()].map(([id, c]) => ({ identifier: id, status: c.status, self_number: c.selfNumber }));
  res.json({ ok: true, status: 'up', chatwoot_url: CHATWOOT_URL, persisted_identifiers: persisted, live_clients: live, uptime_s: Math.round(process.uptime()) });
});

app.get('/admin/api/instances', authenticate, (_req, res) => {
  const persisted = new Set(listPersistedIdentifiers());
  const liveMap = new Map([...manager.clients.entries()].map(([id, c]) => [id, c]));
  const allIds = new Set([...persisted, ...liveMap.keys()]);
  const instances = [...allIds].map((id) => {
    const c = liveMap.get(id);
    return { identifier: id, status: c ? c.status : 'disconnected', self_number: c ? c.selfNumber : null, persisted: persisted.has(id), has_qr: !!(c && c.qr) };
  });
  res.json({ instances });
});

app.get('/admin/api/logs', authenticate, (_req, res) => {
  res.json({ logs: EVENT_LOG.slice(0, 50) });
});

app.get('/admin/api/inbound', authenticate, (req, res) => {
  const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 200);
  const identifier = req.query.identifier ? String(req.query.identifier) : null;
  let items = INBOUND_MESSAGES;
  if (identifier) items = items.filter((m) => m.identifier === identifier);
  res.json({ count: items.length, total: INBOUND_MESSAGES.length, inbound: items.slice(0, limit) });
});

app.delete('/admin/api/inbound', authenticate, (_req, res) => {
  INBOUND_MESSAGES.length = 0;
  res.json({ ok: true });
});

app.get('/admin/api/webhook-status', authenticate, (_req, res) => {
  const persisted = listPersistedIdentifiers();
  const live = [...manager.clients.entries()].map(([id, c]) => ({ identifier: id, status: c.status, self_number: c.selfNumber }));
  const listening = live.filter((c) => c.status === 'connected').map((c) => c.identifier);
  res.json({
    chatwoot_url: CHATWOOT_URL,
    webhook_template: `${CHATWOOT_URL}/webhooks/whatsapp_unofficial/:phone_number`,
    persisted_identifiers: persisted,
    live_clients: live,
    listening_identifiers: listening,
    is_listening: listening.length > 0,
    last_forward: LAST_FORWARD,
    inbound_count: INBOUND_MESSAGES.length,
    inbound_latest: INBOUND_MESSAGES[0] || null,
  });
});

// SSE stream for live inbound messages (EventSource cannot set headers, so token via ?token= is accepted)
app.get('/admin/api/events', (req, res) => {
  const token = extractToken(req);
  if (!SHARED_TOKEN) return res.status(503).json({ error: 'companion_token_not_configured' });
  if (token !== SHARED_TOKEN) return res.status(401).json({ error: 'unauthorized' });

  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive',
  });
  res.write(`event: ready\ndata: ${JSON.stringify({ ts: new Date().toISOString(), inbound_count: INBOUND_MESSAGES.length })}\n\n`);
  SSE_CLIENTS.add(res);
  req.on('close', () => SSE_CLIENTS.delete(res));
});

app.post('/connect', authenticate, async (req, res) => {
  const { identifier } = req.body || {};
  if (!identifier) return res.status(400).json({ error: 'identifier_required' });
  try {
    const status = await manager.connect(identifier);
    return res.json({ status });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get('/qr/:identifier', authenticate, async (req, res) => {
  const { identifier } = req.params;
  if (manager.isConnected(identifier)) return res.sendStatus(204);
  const qrRaw = manager.getQr(identifier);
  if (!qrRaw) return res.sendStatus(204);
  try {
    const png = await qrcode.toDataURL(qrRaw);
    return res.json({ qr: png, status: manager.getStatus(identifier) });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.get('/status/:identifier', authenticate, (req, res) => {
  const { identifier } = req.params;
  return res.json({ status: manager.getStatus(identifier) });
});

app.post('/send', authenticate, async (req, res) => {
  const { identifier, to, type, text, mediaUrl, mediaBase64, mimeType, caption, filename } = req.body || {};
  if (!identifier || !to) return res.status(400).json({ error: 'identifier_and_to_required' });
  try {
    const result = await manager.sendMessage(identifier, { to, type, text, mediaUrl, mediaBase64, mimeType, caption, filename });
    pushLog({ direction: 'outbound', identifier, to, type: type || 'text', status: 'sent', wa_id: result?.key?.id || null });
    return res.json({ id: result?.key?.id || null, status: 'sent' });
  } catch (err) {
    pushLog({ direction: 'outbound-error', identifier, to, error: err.message });
    return res.status(400).json({ error: err.message });
  }
});

app.get('/media/:identifier/:mediaId', authenticate, async (req, res) => {
  const { identifier, mediaId } = req.params;
  try {
    const filePath = await manager.getMediaFile(identifier, mediaId);
    if (!filePath) return res.sendStatus(404);
    return res.sendFile(filePath);
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.post('/logout/:identifier', authenticate, async (req, res) => {
  const { identifier } = req.params;
  try {
    await manager.logout(identifier);
    return res.json({ status: STATUS.DISCONNECTED });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  process.stdout.write(`[companion] listening on :${PORT}\n`);
  if (!SHARED_TOKEN) {
    process.stderr.write('[companion] WARNING: CHATWOOT_SHARED_TOKEN is empty — all authenticated endpoints will return 503 until configured\n');
  }
  restorePersistedSessions();
});

/**
 * After a restart the in-memory client map is empty, but each identifier's Baileys
 * auth state (creds + Signal keys) is persisted on the AUTH_DIR volume. Reconnect
 * every one so a container reload does NOT force a QR re-scan: valid sessions come
 * back up silently, and only genuinely logged-out identifiers emit a fresh QR.
 */
function restorePersistedSessions() {
  const persisted = listPersistedIdentifiers();
  if (persisted.length === 0) return;
  process.stdout.write(`[companion] restoring ${persisted.length} persisted WhatsApp session(s): ${persisted.join(', ')}\n`);
  for (const identifier of persisted) {
    manager.connect(identifier).then((status) => {
      process.stdout.write(`[companion] restored session for ${identifier} -> ${status}\n`);
    }).catch((err) => {
      process.stderr.write(`[companion] failed to restore session for ${identifier}: ${err.message}\n`);
    });
  }
}
