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

// Health-check tuning. The watchdog heals accidental mid-session failures
// (half-open socket, hung connect, missed close event) from persisted creds.
const WATCHDOG_INTERVAL_MS = Number(process.env.WATCHDOG_INTERVAL_MS || 30_000);
const WATCHDOG_STUCK_TIMEOUT_MS = Number(process.env.WATCHDOG_STUCK_TIMEOUT_MS || 120_000);
const WATCHDOG_HEARTBEAT_TIMEOUT_MS = Number(process.env.WATCHDOG_HEARTBEAT_TIMEOUT_MS || 1_800_000);

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

// Resolve an outbound recipient into a valid Baileys JID. `to` may arrive from
// Chatwoot as either a bare phone number (the usual case — the unofficial
// provider stores the contact's plain number, not a suffixed JID) or as an
// already-qualified peer JID (e.g. `<number>@s.whatsapp.net` or `<lid>@lid`).
//
// We accept only a known WhatsApp user suffix and otherwise treat the value as
// a phone number, so a malformed value like `123@jid` is rejected loudly instead
// of being handed to Baileys verbatim (which Baileys silently times out on).
function resolveRecipientJid(to) {
  const raw = String(to || '').trim();
  if (!raw) throw new Error('recipient_required');
  if (/@(s\.whatsapp\.net|c\.us|lid|g\.us)$/.test(raw)) return raw;

  const digits = raw.replace(/\D/g, '');
  if (!digits) throw new Error(`invalid_recipient:${raw}`);
  return `${digits}@s.whatsapp.net`;
}

/**
 * Map a Baileys message into Chatwoot Cloud webhook shape.
 * Chatwoot's Whatsapp::IncomingMessageWhatsappCloudService parses
 *   entry[0].changes[0].value.{messages,contacts,metadata}
 * and resolves the channel by the `:phone_number` URL param (we do NOT set
 * `object: whatsapp_business_account`, which would route to the cloud finder).
 *
 * We pass the FULL remote JID (e.g. `62812...@s.whatsapp.net` or `<lid>@lid`)
 * as the `from`/`wa_id` so Chatwoot can store it verbatim as the contact's
 * source_id. For linked-device (LID) peers the JID is NOT the phone number, so
 * stripping it down to digits would lose the real recipient identity and break
 * outbound replies (the companion sends back to the exact JID it is given).
 */
function toCloudMessage(identifier, selfNumber, message, mediaIds) {
  const from = message.key.remoteJid;
  const cloudMessage = { from, ...buildCloudMessageContent(message, mediaIds) };
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

/**
 * Map a Baileys message sent from the phone itself (fromMe) into Chatwoot's SMB
 * message-echo shape. Chatwoot routes these as `outgoing_echo` messages and
 * stores them with message_type `outgoing`, so outbound messages typed directly
 * in the WhatsApp app show up in the conversation alongside Chatwoot replies.
 *
 * The echo payload reverses the peer fields vs a regular inbound message:
 * `from` is the business number (selfNumber) and `to` is the contact's JID, which
 * is what Chatwoot's echo parser uses to resolve/create the contact. The content
 * block (text/media) is identical to the inbound shape so the shared
 * create_message/attach_files paths work unchanged.
 */
function toCloudEchoMessage(identifier, selfNumber, message, mediaIds) {
  const to = message.key.remoteJid;
  const echoMessage = { from: selfNumber, to, ...buildCloudMessageContent(message, mediaIds) };
  return {
    entry: [
      {
        id: identifier,
        changes: [
          {
            field: 'smb_message_echoes',
            value: {
              metadata: { display_phone_number: selfNumber, phone_number_id: identifier },
              message_echoes: [echoMessage],
            },
          },
        ],
      },
    ],
  };
}

/**
 * Shared inner-message content for both the inbound and echo payloads. The peer
 * (`from`/`to`) fields differ per direction and are added by the wrappers above,
 * so this only builds the type + message body/media block.
 */
function buildCloudMessageContent(message, mediaIds) {
  const msg = message.message || {};
  const base = { id: message.key.id, timestamp: message.messageTimestamp };

  if (msg.conversation || msg.extendedTextMessage?.text) {
    return { ...base, type: 'text', text: { body: msg.conversation || msg.extendedTextMessage.text } };
  }
  if (msg.imageMessage) {
    const id = saveMedia(mediaIds, 'image', msg.imageMessage);
    return { ...base, type: 'image', image: { id, caption: msg.imageMessage.caption } };
  }
  if (msg.videoMessage) {
    const id = saveMedia(mediaIds, 'video', msg.videoMessage);
    return { ...base, type: 'video', video: { id, caption: msg.videoMessage.caption } };
  }
  if (msg.audioMessage) {
    const id = saveMedia(mediaIds, 'audio', msg.audioMessage);
    return { ...base, type: 'audio', audio: { id } };
  }
  if (msg.documentMessage) {
    const id = saveMedia(mediaIds, 'document', msg.documentMessage);
    return { ...base, type: 'document', document: { id, filename: msg.documentMessage.fileName, caption: msg.documentMessage.caption } };
  }
  if (msg.stickerMessage) {
    const id = saveMedia(mediaIds, 'sticker', msg.stickerMessage);
    return { ...base, type: 'sticker', sticker: { id } };
  }
  if (msg.locationMessage) {
    const loc = msg.locationMessage;
    return { ...base, type: 'location', location: { latitude: loc.degreesLatitude, longitude: loc.degreesLongitude, name: loc.name, address: loc.address } };
  }
  if (msg.contactsArrayMessage) {
    // Best-effort: Chatwoot handles the `contacts` message type.
    return { ...base, type: 'contacts', contacts: [] };
  }
  // Unknown / unsupported type -> still forward so Chatwoot can store a placeholder.
  return { ...base, type: 'text', text: { body: '' } };
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
    this.startWatchdog();
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

  startWatchdog() {
    this.watchdogTimer = setInterval(() => this.runWatchdog(), WATCHDOG_INTERVAL_MS);
    if (this.watchdogTimer.unref) this.watchdogTimer.unref();
  }

  /**
   * Periodic health check so an accidental mid-session failure (silent half-open
   * socket, hung connect, missed close event) heals from persisted creds without
   * requiring a fresh QR scan.
   */
  async runWatchdog() {
    const now = Date.now();
    for (const [identifier, client] of [...this.clients.entries()]) {
      if (client.status === STATUS.DISCONNECTED) {
        process.stdout.write(`[companion] watchdog reconnecting ${identifier}\n`);
        await this.connect(identifier);
        continue;
      }

      const stuckConnecting = (client.status === STATUS.CONNECTING || client.status === STATUS.SCANNING) && now - client.lastActivity > WATCHDOG_STUCK_TIMEOUT_MS;
      if (stuckConnecting) {
        this.restartClient(identifier, `stuck in ${client.status}`);
        continue;
      }

      const zombieConnected = client.status === STATUS.CONNECTED && client.sock?.ws?.readyState === 3;
      const staleConnected = client.status === STATUS.CONNECTED && now - client.lastActivity > WATCHDOG_HEARTBEAT_TIMEOUT_MS;
      if (zombieConnected || staleConnected) {
        this.restartClient(identifier, zombieConnected ? 'dead socket' : 'no activity');
      }
    }
  }

  restartClient(identifier, reason) {
    process.stdout.write(`[companion] watchdog restarting ${identifier} (${reason})\n`);
    const existing = this.clients.get(identifier);
    try {
      existing?.sock?.end(new Error(`watchdog: ${reason}`));
    } catch {
      // ws.close() below still forces the socket down
    }
    try {
      existing?.sock?.ws?.close();
    } catch {
      // ignore
    }
    this.clients.delete(identifier);
    this.connect(identifier);
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
      lastActivity: Date.now(),
      companionSentIds: new Set(),
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
      client.lastActivity = Date.now();

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
          setTimeout(() => {
            // Only reconnect if this socket is still the current client; a watchdog
            // restart may have already replaced it with a fresh socket.
            if (this.clients.get(identifier) === client) this.connect(identifier);
          }, 2000);
        }
      }
    });

    sock.ev.on('messages.upsert', async ({ messages }) => {
      client.lastActivity = Date.now();
      for (const m of messages) {
        const remoteJid = m.key.remoteJid || '';
        // Filter out group chats — only direct/private messages should reach Chatwoot
        if (!isPrivateDirectJid(remoteJid)) {
          // // Narrow log so operators can see group traffic is being ignored
          // if (isGroupJid(remoteJid)) process.stdout.write(`[companion] ignored group message from ${remoteJid} for ${identifier}\n`);
          continue;
        }

        // Messages sent from the phone (fromMe) are not Chatwoot-originated, so
        // Chatwoot has no copy of them yet. Capture them as echo messages unless
        // the id matches one this companion already sent on Chatwoot's behalf
        // (those are stored by Chatwoot when the agent replies, so re-forwarding
        // would duplicate them).
        if (m.key.fromMe) {
          if (client.companionSentIds.has(m.key.id)) {
            client.companionSentIds.delete(m.key.id);
            continue;
          }
          try {
            const payload = toCloudEchoMessage(client.identifier, client.selfNumber, m, client.mediaNodes);
            await this.onInbound(client.identifier, payload, client);
          } catch (err) {
            // swallow per-message errors; log to stderr
            process.stderr.write(`[companion] echo error for ${client.identifier}: ${err.message}\n`);
          }
          continue;
        }

        try {
          const payload = toCloudMessage(client.selfNumber || identifier, client.selfNumber, m, client.mediaNodes);
          await this.onInbound(client.identifier, payload, client);
        } catch (err) {
          // swallow per-message errors; log to stderr
          process.stderr.write(`[companion] inbound error for ${client.identifier}: ${err.message}\n`);
        }
      }
    });

    sock.ev.on('messages.update', (updates) => {
      client.lastActivity = Date.now();
      for (const u of updates) {
        if (!u.update?.status) continue;
        // Delivery/read receipts for group messages are not useful in a 1:1 inbox
        if (isGroupJid(u.key.remoteJid)) continue;
        // Chatwoot only understands sent/delivered/read/failed, so map every Baileys
        // status to one of those instead of forwarding e.g. 'server'/'played' verbatim.
        const status = { 1: 'failed', 2: 'sent', 3: 'sent', 4: 'delivered', 5: 'read', 6: 'read' }[u.update.status] || 'sent';
        const payload = {
          entry: [
            {
              id: client.identifier,
              changes: [
                {
                  field: 'messages',
                  value: {
                    metadata: { display_phone_number: client.selfNumber, phone_number_id: client.identifier },
                    statuses: [{ id: u.key.id, status, recipient_id: u.key.remoteJid }],
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
    client.lastActivity = Date.now();

    const jid = resolveRecipientJid(to);
    let result;

    if (type === 'text') {
      result = await client.sock.sendMessage(jid, { text: text || '' });
    } else {
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
        case 'image': result = await client.sock.sendMessage(jid, { image: buffer, mimetype: mimeType || 'image/jpeg', ...content }); break;
        case 'video': result = await client.sock.sendMessage(jid, { video: buffer, mimetype: mimeType || 'video/mp4', ...content }); break;
        case 'audio': result = await client.sock.sendMessage(jid, { audio: buffer, mimetype: mimeType || 'audio/ogg', ptt: false }); break;
        case 'document': result = await client.sock.sendMessage(jid, { document: buffer, mimetype: mimeType || 'application/pdf', ...content }); break;
        case 'sticker': result = await client.sock.sendMessage(jid, { sticker: buffer, mimetype: mimeType || 'image/webp' }); break;
        default: throw new Error(`unsupported_type:${type}`);
      }
    }

    // Baileys echoes every sent message back through messages.upsert as fromMe.
    // Remember the id so the echo handler skips it — Chatwoot already stores the
    // message it created when it called /send, and re-forwarding would duplicate it.
    if (result?.key?.id) {
      client.companionSentIds.add(result.key.id);
      // Bound the set: ids are only needed for the short window until Baileys
      // echoes the sent message, so dropping the oldest is safe.
      if (client.companionSentIds.size > 1000) {
        client.companionSentIds.delete(client.companionSentIds.values().next().value);
      }
    }

    return result;
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
