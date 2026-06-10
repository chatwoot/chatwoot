# ADR-0001: Chatwoot Community Edition as the Unified Chat Panel core

- **Status:** Accepted
- **Date:** 2026-06-10

## Context
We need an OSS, self-hostable omni-channel inbox with human-agent UI, conversation/contact
storage, and an extension point for our own AI. Building this from scratch is expensive and off
our core value (the agents). Evaluated Chatwoot, Rocket.Chat, Botpress/Typebot, Tinode, and
2026 AI-native entrants (tgo, evo-crm-community, synkora).

## Decision
Use **Chatwoot CE (MIT)** as the core, in **headless/agent-bot mode**: it owns channels,
conversations, human handoff state, and the agent UI; we attach AI via the agent-bot webhook +
REST API. We do **not** fork Chatwoot and do **not** use its paid Captain AI.

## Consequences
- (+) Mature (50k+ installs), best human-agent UX, native WhatsApp/IG/TG-bot/web, clean API.
- (+) Stays on free MIT code; our AI/UI stay fully in our control; Claude usable (Captain can't).
- (−) Self-host ops burden (Postgres/Sidekiq/Redis) — mitigate with HA Postgres early.
- (−) Enterprise features are paid per-seat; we avoid depending on `enterprise/` in production.

## Alternatives considered
- tgo / evo-crm-community / synkora — promising but young (2026); used as references, not core.
- Rocket.Chat — team-chat-first, heavier. Botpress/Typebot — bot-first, weak human inbox.
- Fully custom / Tinode — rebuilds the tedious channel plumbing; violates "minimize custom".
