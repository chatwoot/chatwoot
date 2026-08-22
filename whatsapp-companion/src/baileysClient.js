/**
 * Baileys multi-device WhatsApp client manager.
 *
 * One Baileys socket = one WhatsApp number. Auth state (creds + Signal keys)
 * is persisted to AUTH_DIR/<identifier> so the session survives restarts
 * WITHOUT re-scanning the QR code.
 *
 * This module is intentionally framework-free and emits Chatwoot Cloud-shaped
 * payloads to a caller-supplied `onInbound(identifier, payload)` callback so the
 * HTTP layer (index.js) only has to forward to Chatwoot.
 */

import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {
  default as makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion,
  downloadMediaMessage,
} from '@whiskeysockets/baileys';

const AUTH_DIR = process.env.AUTH_DIR || '/app/auth';
const MEDIA_DIR = process.env.MEDIA_DIR || '/app/media';

// Baileys logs a lot; keep it quiet with a no-op logger (avoids a pino dependency).
const nullLogger = {
  level: 'silent',
  info: () => {},
  error: () => {},
  warn: () => {},
  debug: () => {},
  trace: () => {},
  fatal: () => {},
  child: () => nullLogger,
};

const STATUS = {
  DISCONNECTED: 'disconnected',
  CONNECTING: 'connecting',
  SCANNING: 'scanning',
  CONNECTED: 'connected',
};

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function authDirFor(identifier) {
  return path.join(AUTH_DIR, identifier);
}

function mediaPathFor(mediaId) {
  return path.join(MEDIA_DIR, mediaId);
}

function isGroupJid(jid) {
  if (!jid) return false;
  return jid.endsWith('@g.us') || jid === 'status@broadcast' || jid.endsWith('@broadcast');
}

function isPrivateDirectJid(jid) {
  if (!jid) return false;
  if (isGroupJid(jid)) return false;
  // Direct 1:1 chats come as @s.whatsapp.net (current), @c.us (legacy), or @lid (new linked-device id)
  return jid.endsWith('@s.whatsapp.net') || jid.endsWith('@c.us') || jid.endsWith('@lid');
}

/**
 * Map a Baileys message into Chatwoot Cloud webhook shape.
 * Chatwoot's Whatsapp::IncomingMessageWhatsappCloudService parses
 *   entry[0].changes[0].value.{messages,contacts,metadata}
 * and resolves the channel by the `:phone_number` URL param (we do NOT set
 * `object: whatsapp_business_account`, which would route to the cloud finder).
 */
function toCloudMessage(identifier, selfNumber, message, mediaIds) {
  const msg = message.message || {};
  const from = message.key.remoteJid.replace('@s.whatsapp.net', '').replace('@c.us', '');

  let cloudMessage;
  if (msg.conversation || msg.extendedTextMessage?.text) {
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'text', text: { body: msg.conversation || msg.extendedTextMessage.text } };
  } else if (msg.imageMessage) {
    const id = saveMedia(mediaIds, 'image', msg.imageMessage);
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'image', image: { id, caption: msg.imageMessage.caption } };
  } else if (msg.videoMessage) {
    const id = saveMedia(mediaIds, 'video', msg.videoMessage);
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'video', video: { id, caption: msg.videoMessage.caption } };
  } else if (msg.audioMessage) {
    const id = saveMedia(mediaIds, 'audio', msg.audioMessage);
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'audio', audio: { id } };
  } else if (msg.documentMessage) {
    const id = saveMedia(mediaIds, 'document', msg.documentMessage);
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'document', document: { id, filename: msg.documentMessage.fileName, caption: msg.documentMessage.caption } };
  } else if (msg.stickerMessage) {
    const id = saveMedia(mediaIds, 'sticker', msg.stickerMessage);
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'sticker', sticker: { id } };
  } else if (msg.locationMessage) {
    const loc = msg.locationMessage;
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'location', location: { latitude: loc.degreesLatitude, longitude: loc.degreesLongitude, name: loc.name, address: loc.address } };
  } else if (msg.contactsArrayMessage) {
    // Best-effort: Chatwoot handles the `contacts` message type.
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'contacts', contacts: [] };
  } else {
    // Unknown / unsupported type -> still forward so Chatwoot can store a placeholder.
    cloudMessage = { from, id: message.key.id, timestamp: message.messageTimestamp, type: 'text', text: { body: '' } };
  }

  return {
    entry: [
      {
        id: identifier,
        changes: [
          {
            field: 'messages',
            value: {
              metadata: { display_phone_number: selfNumber, phone_number_id: identifier },
              contacts: [{ profile: { name: message.pushName || from }, wa_id: from }],
              messages: [cloudMessage],
            },
          },
        ],
      },
    ],
  };
}

function saveMedia(mediaIds, type, node) {
  const id = crypto.randomBytes(16).toString('hex');
  // Store with type so getMediaFile can reconstruct the Baileys wrapper
  // { imageMessage: node } vs { videoMessage: node } etc.
  mediaIds.set(id, { type, node });
  return id;
}

export class BaileysManager {
  constructor({ onInbound } = {}) {
    this.clients = new Map(); // identifier -> client state
    this.onInbound = onInbound || (() => {});
    ensureDir(AUTH_DIR);
    ensureDir(MEDIA_DIR);
  }

  getStatus(identifier) {
    const client = this.clients.get(identifier);
    return client ? client.status : STATUS.DISCONNECTED;
  }

  getQr(identifier) {
    const client = this.clients.get(identifier);
    return client ? client.qr : null;
  }

  isConnected(identifier) {
    return this.getStatus(identifier) === STATUS.CONNECTED;
  }

  /**
   * Start (or restart) a socket for `identifier`. If a phone number is already
   * connected it is a no-op. Safe to be re-called (e.g. after a transient drop).
   */
  async connect(identifier) {
    if (this.clients.has(identifier) && this.clients.get(identifier).status !== STATUS.DISCONNECTED) {
      return this.getStatus(identifier);
    }

    const authDir = authDirFor(identifier);
    ensureDir(authDir);
    const { state, saveCreds } = await useMultiFileAuthState(authDir);

    const client = {
      identifier,
      status: STATUS.CONNECTING,
      qr: null,
      sock: null,
      saveCreds,
      mediaNodes: new Map(),
      selfNumber: identifier,
    };
    this.clients.set(identifier, client);

    const { version } = await fetchLatestBaileysVersion().catch(() => ({ version: [2, 3000, 0] }));

    const sock = makeWASocket({
      version,
      auth: state,
      logger: nullLogger,
      printQRInTerminal: false,
      connectTimeoutMs: 60_000,
      defaultQueryTimeoutMs: 60_000,
      markOnlineOnConnect: false,
    });
    client.sock = sock;

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        client.qr = qr;
        client.status = STATUS.SCANNING;
      }

      if (connection === 'open') {
        client.status = STATUS.CONNECTED;
        client.qr = null;
        client.selfNumber = sock.user?.id?.split(':')[0]?.replace('@s.whatsapp.net', '') || identifier;
      }

      if (connection === 'close') {
        const statusCode = lastDisconnect?.error?.output?.statusCode;
        const loggedOut = statusCode === DisconnectReason.loggedOut;
        client.status = STATUS.DISCONNECTED;
        client.qr = null;

        if (loggedOut) {
          // Clear persisted auth so a fresh QR is required.
          this.clearAuth(identifier);
          this.clients.delete(identifier);
        } else {
          // Transient disconnect (network blip / restart) -> auto reconnect from saved creds.
          setTimeout(() => this.connect(identifier), 2000);
        }
      }
    });

    sock.ev.on('messages.upsert', async ({ messages }) => {
      for (const m of messages) {
        if (m.key.fromMe) continue; // only inbound to Chatwoot
        const remoteJid = m.key.remoteJid || '';
        // Filter out group chats — only direct/private messages should reach Chatwoot
        if (!isPrivateDirectJid(remoteJid)) {
          // Narrow log so operators can see group traffic is being ignored
          if (isGroupJid(remoteJid)) process.stdout.write(`[companion] ignored group message from ${remoteJid} for ${identifier}\n`);
          continue;
        }
        try {
          const payload = toCloudMessage(client.selfNumber || identifier, client.selfNumber, m, client.mediaNodes);
          await this.onInbound(client.identifier, payload, client);
        } catch (err) {
          ;// swallow per-message errors; log to stderr
          process.stderr.write(`[companion] inbound error for ${client.identifier}: ${err.message}\n`);
        }
      }
    });

    sock.ev.on('messages.update', (updates) => {
      for (const u of updates) {
        if (!u.update?.status) continue;
        // Delivery/read receipts for group messages are not useful in a 1:1 inbox
        if (isGroupJid(u.key.remoteJid)) continue;
        const status = ['', 'error', 'pending', 'server', 'delivered', 'read', 'played'][u.update.status] || 'sent';
        const payload = {
          entry: [
            {
              id: client.identifier,
              changes: [
                {
                  field: 'messages',
                  value: {
                    metadata: { display_phone_number: client.selfNumber, phone_number_id: client.identifier },
                    statuses: [{ id: u.key.id, status, recipient_id: u.key.remoteJid?.replace('@s.whatsapp.net', '') }],
                  },
                },
              ],
            },
          ],
        };
        this.onInbound(client.identifier, payload, client);
      }
    });

    return client.status;
  }

  /**
   * Resolve a media id to a local file path (downloading from WhatsApp if not
   * yet cached). Returns null if not available.
   */
  async getMediaFile(identifier, mediaId) {
    const client = this.clients.get(identifier);
    if (!client || !client.sock) return null;

    const cached = mediaPathFor(mediaId);
    if (fs.existsSync(cached)) return cached;

    const entry = client.mediaNodes.get(mediaId);
    if (!entry) return null;

    // Backwards compat: old entries were bare node, new are {type,node}
    const type = entry.type || 'document';
    const node = entry.node || entry;

    try {
      const wrapKey = {
        image: 'imageMessage',
        video: 'videoMessage',
        audio: 'audioMessage',
        document: 'documentMessage',
        sticker: 'stickerMessage',
      }[type] || 'documentMessage';
      const pseudoMessage = { key: { remoteJid: `${client.selfNumber}@s.whatsapp.net`, id: mediaId }, message: { [wrapKey]: node } };
      const buffer = await downloadMediaMessage(pseudoMessage, 'buffer', {}, { logger: nullLogger });
      fs.writeFileSync(cached, buffer);
      return cached;
    } catch (err) {
      process.stderr.write(`[companion] media download failed for ${mediaId}: ${err.message}\n`);
      return null;
    }
  }

  async sendMessage(identifier, { to, type = 'text', text, mediaUrl, mediaBase64, mimeType, caption, filename }) {
    const client = this.clients.get(identifier);
    if (!client || !client.sock) throw new Error('not_connected');
    if (client.status !== STATUS.CONNECTED) throw new Error('not_connected');

    const jid = to.includes('@') ? to : `${to.replace(/\D/g, '')}@s.whatsapp.net`;

    if (type === 'text') {
      return client.sock.sendMessage(jid, { text: text || '' });
    }

    let buffer;
    if (mediaBase64) {
      buffer = Buffer.from(mediaBase64, 'base64');
    } else if (mediaUrl) {
      const res = await fetch(mediaUrl);
      if (!res.ok) throw new Error(`media_fetch_failed:${res.status}`);
      buffer = Buffer.from(await res.arrayBuffer());
    } else {
      throw new Error('media_required');
    }

    const content = { caption: caption || undefined };
    if (filename) content.fileName = filename;

    switch (type) {
      case 'image': return client.sock.sendMessage(jid, { image: buffer, mimetype: mimeType || 'image/jpeg', ...content });
      case 'video': return client.sock.sendMessage(jid, { video: buffer, mimetype: mimeType || 'video/mp4', ...content });
      case 'audio': return client.sock.sendMessage(jid, { audio: buffer, mimetype: mimeType || 'audio/ogg', ptt: false });
      case 'document': return client.sock.sendMessage(jid, { document: buffer, mimetype: mimeType || 'application/pdf', ...content });
      case 'sticker': return client.sock.sendMessage(jid, { sticker: buffer, mimetype: mimeType || 'image/webp' });
      default: throw new Error(`unsupported_type:${type}`);
    }
  }

  async logout(identifier) {
    const client = this.clients.get(identifier);
    try {
      if (client?.sock) {
        await client.sock.logout();
      }
    } catch (_) {
      // ignore logout errors (already disconnected)
    }
    this.clearAuth(identifier);
    this.clients.delete(identifier);
  }

  clearAuth(identifier) {
    const dir = authDirFor(identifier);
    if (fs.existsSync(dir)) {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  }
}

export { STATUS, mediaPathFor };
