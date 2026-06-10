---
description: Wire a new messaging channel into the Chatwoot inbox
---

Add the channel **$ARGUMENTS** to Omni-Chat-AI.

1. Decide native vs connector using `docs/knowledge/channels.md`:
   - Native (web, Telegram bot, WhatsApp Cloud API, Instagram, FB, email, SMS) → configure a
     Chatwoot inbox; no custom code.
   - Personal/unofficial (personal Telegram/Viber → E-Chat; personal WhatsApp → Evolution) →
     build a thin connector that posts inbound messages to a Chatwoot **API-channel** inbox and
     relays agent replies from Chatwoot's outgoing webhook.
2. Never double-route the same messages through KeyCRM chat. One inbox = Chatwoot.
3. For personal accounts: isolate the number, human-like pacing, never the business-critical number.
4. Document the setup in `docs/knowledge/channels.md`; add an ADR if it changes architecture.
