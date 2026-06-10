# PRD — Omni-Chat-AI (Unified Chat Panel with AI Agents)

**Status:** Draft v1 · **Owner:** Founder · **Last updated:** 2026-06-10
**Related:** [`../architecture.md`](../architecture.md) · ADRs in [`../adr/`](../adr/)

> PRD conventions used here: problem → goals/non-goals → personas → user flows → screens →
> functional logic → data → metrics → rollout → risks → open questions. Each requirement is
> testable. Keep this doc the single source of product truth; implementation detail lives in
> ADRs and code.

---

## 1. Problem & background
The business communicates with customers across many messengers (web widget, Telegram bot +
**personal** Telegram, **personal** Viber, WhatsApp, Instagram DM) and runs operations in
**KeyCRM**. Conversations are fragmented across apps; responses are slow; sales opportunities
(upsell/cross-sell) are missed; and there is no system that learns from past conversations.

We will build an **internal** Unified Chat Panel where all channels land in one inbox, **AI
agents** handle customers (support, consultation, warranty/service, sales), **managers**
supervise and take over via clean handoff, and the system **self-evaluates and self-improves**.
Starts as an internal tool; may later become SaaS.

## 2. Goals / Non-goals
**Goals (v1):**
- G1. One inbox for all channels (incl. personal Telegram/Viber, WhatsApp, Instagram, web).
- G2. AI agents resolve common support/consultation autonomously; escalate cleanly to humans.
- G3. Managers can monitor, approve-before-send (copilot), and take over any conversation.
- G4. AI reads/writes KeyCRM (orders, buyers, warranty, catalog).
- G5. Sales agent raises AOV via context-aware upsell, gated on customer sentiment.
- G6. Every conversation is traced and quality-scored; resolved answers feed back into the KB.
- G7. No OpenAI lock-in — Claude primary, provider-swappable.

**Non-goals (v1):** public multi-tenant SaaS billing; voice calls; autonomous refunds/payments
without human approval; fine-tuning custom models.

## 3. Personas
- **Customer** — messages from any channel; wants fast, accurate help and easy purchase.
- **Manager/Agent** — supervises AI, handles escalations, approves sensitive replies.
- **Admin/Founder** — configures channels, agents, prompts, KB, and reviews analytics.

## 4. User flows

### F1 — AI-handled support (happy path)
1. Customer sends a message on any channel → lands in Chatwoot as a `pending` conversation.
2. AI Support agent reads history, looks up order in KeyCRM, answers from KB.
3. Customer satisfied → AI resolves (or leaves open for confirmation). Trace logged to Langfuse.

### F2 — Escalation / handoff to human
1. AI detects low confidence / refund / anger / explicit "human" / high-value sale.
2. AI posts a customer-facing handoff line + a private summary note for the manager.
3. Conversation flips `pending → open`; automation routes to the right team/agent.
4. Manager takes over with full context; may return to bot (`open → pending`) when done.

### F3 — Manager copilot (approve-before-send)
1. On a high-value inbox, AI drafts a reply but does **not** send.
2. Manager sees the draft suggestion, edits if needed, clicks send.

### F4 — Sales / AOV uplift
1. During a buying conversation, Sales agent recommends in-stock complementary items from the
   KeyCRM catalog based on the customer's cart/history.
2. Upsell is suppressed if sentiment is negative or the customer is in a support/complaint flow.
3. On close, agent creates/updates the order or pipeline card in KeyCRM.

### F5 — Connect a personal channel (admin)
1. Admin adds a personal Telegram/Viber number via the E-Chat bridge (or WhatsApp via Evolution).
2. Bridge authorizes the number (device-sync/QR) and forwards messages into a Chatwoot API inbox.

### F6 — Self-learning loop
1. Resolved conversations + new KB articles are indexed into the vector store.
2. Future answers retrieve the improved KB; quality scores tracked over time in Langfuse.

## 5. Screens (in Chatwoot, plus admin)
- **Unified inbox** — all channels, conversation list, status (pending/open/resolved), filters.
- **Conversation view** — full thread, customer profile, KeyCRM order panel (dashboard app),
  AI draft/suggestion area, private notes, handoff control.
- **Queue/health** — split of `pending` (bot-owned) vs `open` (needs human); priority/labels.
- **Admin: channels** — connect/disconnect inboxes & bridges; per-inbox mode (autopilot/copilot).
- **Admin: agents & prompts** — system prompts, tools enabled, KB sources per agent.
- **Analytics** — resolution rate, handoff rate, CSAT/sentiment, AOV/conversion attributed to AI,
  LLM quality scores (from Langfuse).

## 6. Functional logic (key rules)
- **Ownership:** bot owns `pending`; human owns `open`. The bot never replies on `open`.
- **Escalation triggers:** confidence threshold; refund/complaint intent; negative sentiment;
  explicit human request; order value above threshold. Any trigger → handoff (no AI loops).
- **Grounding:** AI must use tools for order/customer facts; never fabricate. KB gaps → escalate.
- **Upsell gate:** only when intent=buying AND sentiment≥neutral.
- **Model routing:** all LLM calls go through LiteLLM alias `claude-primary` (fallbacks configured).

## 7. Data & integrations
- **Chatwoot:** conversations, contacts, messages, status, automation. (System of record for chat.)
- **KeyCRM:** orders, buyers, products/offers, stock, pipelines/cards; webhooks for order/payment/
  lead status. (System of record for commerce.) Rate limit 60 rpm/IP — cache & batch.
- **Vector store (Qdrant/pgvector):** KB chunks, FAQs, resolved answers.
- **Langfuse:** traces, scores, datasets, experiments.

## 8. Success metrics
- **Product:** % conversations resolved without human; median first-response time; handoff rate;
  CSAT/sentiment; AOV and chat-attributed conversion/ROAS.
- **Quality:** LLM-as-judge correctness & faithfulness scores; hallucination rate; regression
  pass-rate in CI (Promptfoo/Langfuse experiments).
- **Ops:** cost per conversation (via LiteLLM/Langfuse); p95 latency.

## 9. Rollout (maps to architecture phases)
P0 foundation → P1 support agent → P2 handoff+managers → P3 personal channels → P4 sales+self-
learning → P5 scale/SaaS. Each phase ships behind a flag; quality gates in CI before promote.

## 10. Risks
- Personal-account bans (accepted) — isolate numbers, human-like pacing, never the core number.
- AI hallucination — grounding + faithfulness eval + escalate on KB gaps.
- Over-aggressive upsell hurting CSAT — sentiment gating + manager review on high value.
- Chatwoot ops at scale — HA Postgres, Sidekiq tuning early.

## 11. Open questions
- Which inboxes start in copilot vs autopilot at launch?
- AOV/ROAS attribution window (24–48h vs 30d)?
- Languages at launch (RU/UK/EN)?
