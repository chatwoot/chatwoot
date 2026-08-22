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
import { BaileysManager, STATUS, mediaPathFor } from './baileysClient.js';

const PORT = Number(process.env.PORT || 4000);
const SHARED_TOKEN = process.env.CHATWOOT_SHARED_TOKEN || '';
const CHATWOOT_URL = (process.env.CHATWOOT_URL || 'http://rails:3000').replace(/\/+$/, '');

const app = express();
app.use(express.json({ limit: '25mb' }));

const FORWARD_MAX_ATTEMPTS = 5;
const FORWARD_BASE_DELAY_MS = 1000;

async function forwardToChatwoot(identifier, body) {
  const url = `${CHATWOOT_URL}/webhooks/whatsapp_unofficial/${encodeURIComponent(identifier)}`;

  for (let attempt = 1; attempt <= FORWARD_MAX_ATTEMPTS; attempt += 1) {
    let response;
    try {
      response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-companion-token': SHARED_TOKEN,
        },
        body,
      });
    } catch (err) {
      // Network-level failure (connection refused, DNS, timeout). Retry with
      // backoff so a transient Chatwoot restart doesn't drop the customer message.
      if (attempt < FORWARD_MAX_ATTEMPTS) {
        await delay(FORWARD_BASE_DELAY_MS * attempt);
        continue;
      }
      process.stderr.write(`[companion] inbound forward error for ${identifier}: ${err.message}\n`);
      return;
    }

    if (response.ok) return;

    // Failure responses (4xx/5xx) won't resolve after retries.
    process.stderr.write(`[companion] inbound forward failed ${response.status} for ${identifier}\n`);
    return;
  }
}

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const manager = new BaileysManager({
  onInbound: async (identifier, payload, _client) => {
    const body = typeof payload === 'string' ? payload : JSON.stringify(payload);
    await forwardToChatwoot(identifier, body);
  },
});

function authenticate(req, res, next) {
  if (!SHARED_TOKEN) {
    process.stderr.write('[companion] CHATWOOT_SHARED_TOKEN not configured — rejecting request\n');
    return res.status(503).json({ error: 'companion_token_not_configured', hint: 'Set CHATWOOT_SHARED_TOKEN in companion and WHATSAPP_COMPANION_TOKEN in Chatwoot' });
  }
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : req.headers['x-companion-token'];
  if (token === SHARED_TOKEN) return next();
  return res.status(401).json({ error: 'unauthorized' });
}

app.get('/health', (_req, res) => res.json({ ok: true, status: 'up' }));

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
    return res.json({ id: result?.key?.id || null, status: 'sent' });
  } catch (err) {
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
});
