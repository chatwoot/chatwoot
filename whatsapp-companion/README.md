# Chatwoot WhatsApp Companion (Unofficial / QR login)

A small, self-contained bridge that lets Chatwoot send and receive WhatsApp
messages through an **unofficial multi-device** connection (Baileys) — i.e. you
log in by scanning a QR code with the WhatsApp app, no Meta Business account, no
phone-number-id, no template approval.

This service holds the long-lived WhatsApp WebSocket and proxies messages to/from
Chatwoot. It is **decoupled** from Chatwoot so you can run, update, or remove it
independently. Chatwoot talks to it over HTTP with a shared token.

> ⚠️ Unofficial access violates WhatsApp's Terms of Service and numbers can be
> banned, especially for bulk/marketing sends. Treat this as best-effort / test
> numbers, not your primary campaign channel. The official Cloud API (already in
> Chatwoot) is safer for real blasts.

## Architecture

```
WhatsApp  <->  companion (Baileys WS)  <->  Chatwoot (HTTP)
   inbound: WA -> companion -> POST /webhooks/whatsapp_unofficial/:phone
   outbound: Chatwoot -> POST companion /send -> WA
   login:   companion emits QR -> Chatwoot polls + shows QR -> scan
```

## Run (standalone, for dev)

```bash
npm install
CHATWOOT_SHARED_TOKEN=devtoken CHATWOOT_URL=http://localhost:3000 npm start
```

## Docker

```bash
docker build -t chatwoot-whatsapp-companion ./whatsapp-companion
docker run -d --name wa-companion \
  -e CHATWOOT_SHARED_TOKEN=yourtoken \
  -e CHATWOOT_URL=http://host.docker.internal:3000 \
  -v wa-auth:/app/auth -v wa-media:/app/media \
  -p 4000:4000 chatwoot-whatsapp-companion
```

Auth state is persisted to `/app/auth` (mount a volume!). Without it, every
restart forces a re-scan of the QR.

## Environment

| Var | Default | Description |
|-----|---------|-------------|
| `CHATWOOT_SHARED_TOKEN` | `''` | Shared secret Chatwoot uses to authenticate |
| `CHATWOOT_URL` | `http://rails:3000` | Base URL Chatwoot listens on (inbound forward target) |
| `PORT` | `4000` | HTTP listen port |
| `AUTH_DIR` | `/app/auth` | Persisted Baileys auth state |
| `MEDIA_DIR` | `/app/media` | Cache for downloaded media |

## API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Container healthcheck |
| POST | `/connect` | `{ identifier }` — start a socket for a number |
| GET | `/qr/:identifier` | QR PNG (or 204 if already connected) |
| GET | `/status/:identifier` | `connected\|scanning\|disconnected` |
| POST | `/send` | `{ identifier, to, type, text|mediaUrl|mediaBase64, ... }` |
| GET | `/media/:identifier/:mediaId` | Serve downloaded media to Chatwoot |
| POST | `/logout/:identifier` | Clear persisted auth for a number |

## Removing this module

Delete the `whatsapp-companion/` folder and remove the `whatsapp-companion`
service from `docker-compose*.yaml`. Chatwoot changes are guarded by the
`whatsapp_unofficial` provider string — see PLAN.md §8.
