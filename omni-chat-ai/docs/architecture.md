# OMNI-CHAT-AI — Reference Architecture (June 2026)

Production-grade, OSS-first, multi-agent Unified Chat Panel for personal + business
messengers, AI customer agents (support / consultation / warranty / sales), human handoff
to managers, KeyCRM integration, self-learning & self-evaluation. **Not locked to OpenAI** —
Anthropic Claude is the primary brain behind a provider-agnostic model gateway.

This is the committed design. It is opinionated on purpose — one chosen component per layer,
with named OSS repos (verified June 2026), licenses, and rationale. Alternatives are listed
only where a real fork in the road exists.

---

## 0. Design principles
- **OSS-first, build-on-top, minimize custom code.** Buy/borrow the omnichannel inbox, the
  model gateway, the eval stack. Write custom code ONLY in the agent layer (your IP) and the
  thin connectors.
- **Chatwoot owns conversation state + human handoff.** The agent layer stays mostly stateless
  and event-driven. This is what keeps the system simple.
- **Provider-agnostic AI.** Every LLM call goes through LiteLLM → Claude by default, any
  provider as fallback. No vendor lock-in.
- **Single source of truth per concern.** Chatwoot = conversations. KeyCRM = orders/customers.
  Langfuse = traces/eval. Vector DB = knowledge.

---

## 1. Layered architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ CUSTOMERS — every channel                                                      │
│  Web widget · Telegram(bot+personal) · Viber(personal) · WhatsApp(biz+personal)│
│  · Instagram DM · Facebook · Email · SMS                                       │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                 │
┌────────────────────────────────▼─────────────────────────────────────────────┐
│ LAYER 1 — CHANNEL / INGESTION                                                  │
│  NATIVE Chatwoot inboxes:  web widget · Telegram BOT · WhatsApp Cloud API ·    │
│                            Instagram(official) · Facebook · Email · SMS        │
│  CONNECTORS → Chatwoot API channel:                                            │
│   • E-Chat.tech (managed)   → personal Viber + personal Telegram (+opt WA)     │
│   • Evolution API (Baileys) → personal WhatsApp number                         │
│   • (fallback) Telethon     → personal Telegram via MTProto/QR                 │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                 │  signed webhook (message_created, conv=pending)
┌────────────────────────────────▼─────────────────────────────────────────────┐
│ LAYER 2 — UNIFIED CHAT PANEL (core)    ★ CHATWOOT Community Edition (MIT)       │
│  omni-channel inbox · contact/conversation store · human-agent UI · routing ·  │
│  automation rules · agent-bot API · webhooks · handoff state machine           │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                 │  agent-bot webhook (HMAC) ⇄ REST replies
┌────────────────────────────────▼─────────────────────────────────────────────┐
│ LAYER 3 — AI AGENT SERVICE  (your IP, FastAPI)                                 │
│                                                                                │
│   ┌── ORCHESTRATOR (LangGraph, MIT lib) ──────────────────────────────────┐   │
│   │  Supervisor/Router → intent classify → route                          │   │
│   │  state = Postgres checkpointer  (thread_id = Chatwoot conversation id) │   │
│   │  guardrails: input PII/safety → … → output validation                 │   │
│   │     ├─ Support agent                                                   │   │
│   │     ├─ Consultation agent     each = Pydantic AI typed agent           │   │
│   │     ├─ Warranty/Service agent  + focused tools + focused KB slice      │   │
│   │     ├─ Sales agent (AOV/ROAS, upsell — satisfaction-gated)            │   │
│   │     └─ Escalation node → Chatwoot bot_handoff! (pending→open)          │   │
│   └────────────────────────────────────────────────────────────────────────┘  │
│                          │ tools                                               │
│   tools:  keycrm.*  ·  kb.search (RAG)  ·  recommend_upsell  ·  handoff        │
└───────┬───────────────┬───────────────┬───────────────────┬───────────────────┘
        │               │               │                   │
┌───────▼──────┐ ┌──────▼───────┐ ┌─────▼────────┐ ┌────────▼─────────────────┐
│ LAYER 4      │ │ LAYER 5      │ │ LAYER 6      │ │ LAYER 7                   │
│ MODEL GATEWAY│ │ KNOWLEDGE/RAG│ │ CRM / BIZ    │ │ MEMORY                    │
│ LiteLLM      │ │ LlamaIndex + │ │ KeyCRM REST  │ │ Postgres checkpointer     │
│ → Claude     │ │ Qdrant/pgvec │ │ + KeyCRM MCP │ │ (short-term, per-convo) + │
│  (primary),  │ │ (KB, FAQ,    │ │ orders·buyer │ │ Mem0 (long-term,          │
│  any provider│ │  resolved    │ │ ·warranty·   │ │  per-customer facts)      │
│  fallback    │ │  tickets)    │ │  catalog     │ │                           │
└──────────────┘ └──────────────┘ └──────────────┘ └───────────────────────────┘
        ▲                                   ▲
        │ all LLM + tool spans              │ webhooks (order/payment/lead status)
┌───────┴───────────────────────────────────┴───────────────────────────────────┐
│ LAYER 8 — OBSERVABILITY · SELF-EVAL · SELF-LEARNING    ★ LANGFUSE v4 (MIT)      │
│  traces · cost · latency · user feedback · LLM-as-judge · code evaluators ·    │
│  datasets · experiments in CI/CD (fail PR on score drop) · Langfuse MCP        │
│  + Ragas (RAG faithfulness)  + Promptfoo (prompt regression in CI)             │
│  + RAG feedback loop: resolved answers → re-indexed into KB (the real learning)│
└────────────────────────────────────────────────────────────────────────────────┘
┌────────────────────────────────────────────────────────────────────────────────┐
│ LAYER 9 — MANAGER CONTROL (in Chatwoot)                                        │
│  Copilot mode (approve-before-send) on high-value inboxes · Autopilot+handoff  │
│  on FAQ · queue health = pending(bot) vs open(human) · automation routing      │
└────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Component decisions (verified June 2026)

| Layer | Component | Repo / source | License | Why this one |
|---|---|---|---|---|
| Unified Chat Panel (core) | **Chatwoot CE** | github.com/chatwoot/chatwoot | MIT (core) | Most mature OSS omnichannel inbox (50k+ installs), best human-agent UX, clean agent-bot API + webhooks, native WhatsApp/IG/TG-bot/web. Don't rebuild this. |
| Personal Viber/TG (+opt WA) | **E-Chat.tech** (managed) | e-chat.tech | Commercial SaaS | Only realistic path for personal **Viber** (no official API); device-sync like desktop; **native KeyCRM** integration; offloads ban-risk infra. |
| Personal WhatsApp number | **Evolution API** | github.com/EvolutionAPI/evolution-api | (check) | De-facto Baileys gateway with documented Chatwoot integration. Use only for a personal WA number; business number stays on official Cloud API. |
| Personal Telegram (fallback/DIY) | **Telethon** | docs.telethon.dev | MIT | MTProto/QR login if you want to self-host instead of E-Chat. |
| Model gateway | **LiteLLM** | github.com/BerriAI/litellm | MIT | One proxy → Claude primary + any provider; keys, cost caps, routing, fallback in one place. THE answer to "not locked to OpenAI". Langfuse-native. |
| Primary LLM | **Anthropic Claude** (Opus/Sonnet) | api.anthropic.com (via LiteLLM) | — | Strongest reasoning for sales+support; provider-swappable behind LiteLLM. |
| Agent orchestrator | **LangGraph** (library) | github.com/langchain-ai/langgraph | MIT (lib) | Multi-agent routing + escalation tree + durable checkpointer + native interrupt() HITL. ★ Self-host the MIT **library**; avoid Elastic-licensed `langgraph-api`/Platform. |
| In-node agents / tools | **Pydantic AI** | github.com/pydantic/pydantic-ai | MIT | Typed, validated tool calls (perfect for KeyCRM schemas); FastAPI-style DX; half the code. Runs inside LangGraph nodes. |
| RAG / knowledge | **LlamaIndex** + **Qdrant** (or pgvector) | llamaindex / qdrant | MIT / Apache-2 | RAG behind a `kb.search` tool, not as orchestrator. Qdrant for scale, pgvector to start simple. |
| CRM | **KeyCRM** REST + **keycrm-mcp** | openapi.keycrm.app/v1 ; github.com/IvanKlymenko/keycrm-mcp | — / OSS | Full objects (orders/buyers/products/pipelines); 60 rpm/IP; MCP wrapper lets the agent call it as tools directly. |
| Long-term memory | **Mem0** | github.com/mem0ai/mem0 | Apache-2 | Per-customer facts/preferences; add when multi-session personalization is needed. |
| Observability + eval | **Langfuse v4** | github.com/langfuse/langfuse | MIT | Self-host; traces, cost, LLM-as-judge + **code evaluators**, datasets, **experiments in CI/CD**, MCP. The self-eval hub. |
| RAG eval | **Ragas** | github.com/explodinggradients/ragas | Apache-2 | Faithfulness/answer-relevancy (anti-hallucination), offline + sampled online. |
| Prompt CI | **Promptfoo** | github.com/promptfoo/promptfoo | MIT | Prompt regression tests in CI before every prompt change. |
| Guardrails | **Guardrails AI** | github.com/guardrails-ai/guardrails | Apache-2 | PII redaction + output validation for v1 (NeMo later if needed). |

### Reference designs to study (validate the architecture; optional adopt)
- **evolution-foundation/evo-crm-community** — almost this exact stack (Chatwoot-style Rails
  core + Evolution API + Python FastAPI AI processor + Go agent service + MCP, single-tenant,
  self-hosted). Closest existing blueprint. Study it; possibly lift patterns.
- **tgoai/tgo** — AI-agent-first omnichannel (multi-agent, RAG, MCP, multi-LLM). The strongest
  "non-Chatwoot base" if you ever want an AI-native core. Weaker on Viber/IG/Ukraine fit.
- **synkora-ai** (MIT, LiteLLM, Langfuse, HITL) — full agent platform; multi-tenant/SaaS-leaning.

---

## 3. Channel matrix (final, decisive)

| Channel | Path | Native? | Ban risk | Notes |
|---|---|---|---|---|
| Website widget | Chatwoot widget | ✅ | none | flagship |
| Telegram Bot | Chatwoot Telegram | ✅ | none | safest TG path |
| Telegram personal | E-Chat → Chatwoot API channel (or Telethon) | connector | high (accepted) | E-Chat offloads infra |
| Viber personal | E-Chat → Chatwoot API channel | connector | high (accepted) | no official personal API exists |
| WhatsApp business # | Chatwoot WhatsApp Cloud API | ✅ | none | templates, scale |
| WhatsApp personal # | Evolution API → Chatwoot | connector | very high (accepted) | only if a personal WA # is required |
| Instagram DM | Chatwoot Instagram (official) | ✅ | low | needs IG Professional + app review |
| Facebook / Email / SMS | Chatwoot native | ✅ | none | included free |

Rule: **one inbox = Chatwoot.** Do NOT also route the same messages through KeyCRM chat —
KeyCRM stays the CRM/orders system of record; Chatwoot is the conversation surface.

---

## 4. Multi-agent flow (per inbound message)

1. Chatwoot receives message → conversation is `pending` (bot owns it) → HMAC webhook to AI service.
2. **Orchestrator (LangGraph)** loads state by `thread_id = conversation.id`; runs **input guardrail** (PII/safety).
3. **Router** classifies intent → routes to a specialist **Pydantic AI** agent (support / consultation / warranty / sales).
4. Specialist calls tools via **LiteLLM→Claude**: `keycrm.get_order/get_buyer/warranty`, `kb.search` (RAG), `recommend_upsell`.
5. **Output guardrail** validates; reply posted to Chatwoot via REST. Sales upsell is gated on sentiment/confidence.
6. **Escalation node** fires on: low confidence · refund/complaint · anger · high-value sale · explicit "human" request →
   posts a customer-facing handoff line + a `private:true` summary note → flips status `pending→open` (`bot_handoff!`).
7. **Automation rule** routes the now-open conversation to the right team/agent; manager takes over with full history.
8. Every step streamed to **Langfuse** (trace, cost, latency); sampled online **LLM-as-judge** + **Ragas** scoring.
9. Resolved answers feed the **RAG feedback loop** → re-indexed into KB (the real "self-learning").

Manager modes: **Copilot/approve-before-send** on high-value inboxes (agent reviews AI draft);
**Autopilot+handoff** on FAQ inboxes.

---

## 5. Self-learning & self-evaluation (what's real vs hype)
- **Real, do first:** RAG knowledge-base feedback loop (resolved → re-indexed); Langfuse online
  LLM-as-judge + code evaluators on live conversations; Ragas faithfulness; Promptfoo prompt CI;
  business KPIs (chat-attributed conversion / AOV / ROAS) pushed into Langfuse as scores.
- **Add later:** Mem0 per-customer memory; DSPy prompt optimization (after a labeled eval set);
  managed fine-tune for tone/format (only >~100k convos).
- **Avoid early (premature):** RLHF/DPO from manager feedback; "self-evolving agents"; fine-tuning
  for facts (facts live in RAG). LLM weights are frozen in prod — RAG + eval IS the learning.

---

## 6. Infrastructure
- **Containers:** Docker Compose for v1 (→ k8s/Helm when scaling). Services: chatwoot (web+sidekiq),
  postgres (HA early — main hidden cost), redis, ai-agent (FastAPI), litellm, langfuse(+clickhouse),
  qdrant, connectors (e-chat bridge, evolution-api).
- **Secrets:** one vault (e.g. Infisical/Bitwarden SM); LiteLLM holds provider keys centrally.
- **Networking:** connectors and AI service are internal; only Chatwoot + webhook ingress exposed.
- **Future SaaS:** Chatwoot Platform API for multi-tenant provisioning; keep agent service
  multi-tenant-aware (tenant carried in state) from day one to avoid a rewrite.

---

## 7. Phased build plan
- **P0 Foundation:** Chatwoot CE self-hosted (managed Postgres) + native channels (widget, TG bot,
  WhatsApp Cloud API, Instagram). LiteLLM up with Claude. Langfuse up.
- **P1 Agent v1:** LangGraph supervisor + ONE Pydantic AI support agent; tools `keycrm.get_order`,
  `kb.search`, `handoff`. `thread_id`=conversation id. Langfuse tracing from line one.
- **P2 Handoff + managers:** escalation node + automation routing; Copilot mode on high-value inbox.
- **P3 Personal channels:** E-Chat bridge (Viber+Telegram) → Chatwoot API channel; Evolution for
  personal WA if needed. Verify media/latency in a spike.
- **P4 Sales + self-learning:** Sales agent + `recommend_upsell` from KeyCRM catalog/stock/history;
  RAG feedback loop; Ragas + Promptfoo in CI; KPI scores in Langfuse.
- **P5 Scale/SaaS:** Qdrant, Mem0, k8s, multi-tenant via Platform API.

---

## 8. Risks & mitigations
- **Personal-account bans** (accepted) → isolate per number, low volume, human-like pacing
  (E-Chat/exe-gateway style), aged real SIMs; never run the business-critical number unofficially.
- **Chatwoot ops at scale** → HA Postgres + Sidekiq/Redis tuning early; pin versions.
- **LangGraph licensing** → MIT library only; no Platform server without a license.
- **n8n if used as glue** → restrictive "fair-code"; fine internal, not for resale.
- **KeyCRM 60 rpm/IP** → cache + batch; enrich webhooks with `GET /order/{id}`.
- **Doc drift / young OSS** → Chatwoot core is the stable bet; treat 2026 entrants as references.
