# Channels — connection guide & risk

| Channel | Path | Native? | Ban risk |
|---|---|---|---|
| Website widget | Chatwoot widget | yes | none |
| Telegram Bot | Chatwoot Telegram inbox | yes | none |
| Telegram personal | E-Chat bridge → Chatwoot API channel (or Telethon) | connector | high (accepted) |
| Viber personal | E-Chat bridge → Chatwoot API channel | connector | high (accepted) |
| WhatsApp business # | Chatwoot WhatsApp Cloud API | yes | none |
| WhatsApp personal # | Evolution API (Baileys) → Chatwoot | connector | very high (accepted) |
| Instagram DM | Chatwoot Instagram (official API) | yes | low |
| Facebook / Email / SMS | Chatwoot native | yes | none |

## Connector pattern (non-native channels)
A small stateless service: receives a platform event → maps platform user to a Chatwoot contact
→ `POST` an incoming message to a **Chatwoot API-channel** inbox → subscribes to Chatwoot's
outgoing webhook → relays agent replies back out. The API channel has no outbound time-window
restriction, which is why personal-account bridges land there.

## Rules
- One inbox = Chatwoot. Do **not** also route the same messages through KeyCRM chat.
- Isolate each personal number; human-like pacing; never run the business-critical number unofficially.
