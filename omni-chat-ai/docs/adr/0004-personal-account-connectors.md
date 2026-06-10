# ADR-0004: Personal-account channels via managed/bridge connectors

- **Status:** Accepted
- **Date:** 2026-06-10

## Context
We must connect **personal** Telegram and Viber accounts and optionally a personal WhatsApp
number. Personal Viber has **no** official API; personal Telegram/WhatsApp automation violates
ToS (ban risk). The founder accepts the risk and prioritizes coverage.

## Decision
- **Personal Viber + personal Telegram:** use the **E-Chat.tech** managed bridge (device-sync;
  native KeyCRM support) → forward into a **Chatwoot API-channel** inbox.
- **Personal WhatsApp number:** **Evolution API** (Baileys) → Chatwoot. **Business WhatsApp**
  number stays on the **official Cloud API** (no ban risk, templates, scale).
- **Fallback** for self-hosting personal Telegram: **Telethon** (MTProto/QR).
- One inbox = Chatwoot; do not double-route the same messages through KeyCRM chat.

## Consequences
- (+) Full coverage incl. otherwise-impossible personal Viber; ban-risk infra offloaded to E-Chat.
- (−) Residual ban risk remains; vendor dependency (uptime/pricing/media support) — verify in a spike.
- (−) Never run the business-critical number unofficially.

## Alternatives considered
- DIY Telethon + Evolution for everything — more custom code/ops; E-Chat reduces it for Viber/TG.
- Official APIs only — drops personal Viber/Telegram entirely; rejected per requirements.
