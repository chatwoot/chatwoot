# AirysChat — Fork Plan & Progress Tracker

> Fork of [chatwoot/chatwoot](https://github.com/chatwoot/chatwoot) → [gabrieldeholanda/AirysChat](https://github.com/gabrieldeholanda/AirysChat)

**TL;DR** — Fork the MIT core of Chatwoot (Rails 7.1 + Vue 3 + pgvector + Redis + Sidekiq). Replace the proprietary `enterprise/` directory with a custom `saas/` module. Add Stripe billing (hybrid base plan + metered AI usage), a LiteLLM Python sidecar to abstract all LLM providers, a custom AI Agent engine (RAG + tool-calling + voice + hybrid), and a visual Agent Builder UI built in Vue 3. Deployed as Docker Compose.

---

## Progress Overview

| Phase | Name | Status | Commit |
|-------|------|--------|--------|
| 0 | Fork & Baseline | ✅ Complete | `d4a5c27` |
| 1 | Custom Branding | ✅ Complete | `b5920d6` |
| 1.5 | All-locale Branding Fix | ✅ Complete | `c5e114c` |
| 2 | Stripe Billing | ✅ Complete | `a63e52c` |
| 3 | LiteLLM Sidecar | ⬜ Not Started | — |
| 4 | AI Agent Engine | ⬜ Not Started | — |
| 5 | Agent Builder UI | ⬜ Not Started | — |
| 6 | Docker Deployment | ⬜ Not Started | — |

---

## Phase 0 — Fork & Baseline Setup ✅

**Commit:** `d4a5c27` — `chore(phase-0): fork cleanup and saas module scaffold`

### What was done

1. Forked `chatwoot/chatwoot` → `gabrieldeholanda/AirysChat`. Configured remotes:
   - `origin` → `git@github.com:gabrieldeholanda/AirysChat.git` (push enabled)
   - `upstream` → `https://github.com/chatwoot/chatwoot.git` (push disabled via `no_push`)
2. Removed the `enterprise/` directory entirely.
3. Created the `saas/` module directory tree mirroring the enterprise structure:
   ```
   saas/
   ├── app/
   │   ├── controllers/api/v1/
   │   ├── helpers/
   │   ├── jobs/
   │   ├── listeners/
   │   ├── mailers/
   │   ├── models/
   │   ├── policies/
   │   ├── serializers/
   │   ├── services/{agent,llm,rag,voice}/
   │   └── views/layouts/
   ├── config/initializers/
   ├── lib/tasks/
   ├── spec/
   └── tasks_railtie.rb
   ```
4. Patched `config/application.rb` — replaced all `enterprise/` autoload paths with `saas/` paths.
5. Patched `lib/chatwoot_app.rb`:
   - `saas?` method returns true
   - `enterprise?` returns false
   - `extensions` returns `["saas"]` (enables `InjectEnterpriseEditionModule` to auto-discover `Saas::*` modules)
6. Created `.github/workflows/upstream-sync.yml` — weekly automated sync from upstream via PR.

---

## Phase 1 — Custom Branding ✅

**Commit:** `b5920d6` — `feat(phase-1): AirysChat custom branding`

### What was done

1. **Color tokens** — Replaced brand blue (`#2781F6`) with AirysChat teal-green (`#1BFBBD`) in `theme/colors.js`.
2. **Iris color scale** — Replaced the full 12-step `--iris-*` scale in `_next-colors.scss` for light/dark themes.
3. **Logo + favicon** — Replaced all logo/favicon assets in `app/assets/images/` and `public/`.
4. **Installation config** — Updated `config/installation_config.yml`:
   - `INSTALLATION_NAME` = AirysChat
   - `BRAND_NAME` = AirysChat
   - `DEPLOYMENT_ENV` = cloud
   - `BRAND_URL` = https://chat.airys.com.br
5. **EN locale strings** — Replaced "Chatwoot" → "AirysChat" in English locale files.

---

## Phase 1.5 — All-locale Branding Fix ✅

**Commit:** `c5e114c` — `fix(branding): replace Chatwoot with AirysChat across all 645 locale files`

### What was done

1. Bulk-replaced "Chatwoot" → "AirysChat" across all 645+ locale files (every supported language).
2. Fixed accidentally renamed interpolation keys: `{latestAirysChatVersion}` → `{latestChatwootVersion}` in 55 files.

---

## Phase 2 — Stripe Billing ✅

**Commit:** `a63e52c` — `feat(billing): add Stripe billing with plans, subscriptions, and AI usage tracking`
**26 files changed, +1120 / -178 lines**

### Data model

| Model | Key columns |
|-------|-------------|
| `Saas::Plan` | name, stripe_product_id, stripe_price_id, price_cents, interval, agent_limit, inbox_limit, ai_tokens_monthly, features (JSONB), active |
| `Saas::Subscription` | account_id, saas_plan_id, stripe_subscription_id, stripe_customer_id, status (enum), periods, trial_end |
| `Saas::AiUsageRecord` | account_id, provider, model, tokens_input, tokens_output, cost_microcents, feature, recorded_on |

### Backend components

- **StripeService** — create_customer, create_checkout_session, create_billing_portal_session, webhook handlers
- **Webhook controller** — Stripe signature verification, event routing
- **Billing API controller** — checkout, subscription, limits, plans endpoints
- **Account extensions** — has_one subscription, usage limits, auto-assign default plan
- **Super Admin Plans CRUD** — via Administrate dashboard
- **Seed rake task** — 4 default plans: Free ($0), Starter ($29), Pro ($99), Enterprise ($299)

### Routes added

- `POST /saas/api/v1/accounts/:id/checkout`
- `GET  /saas/api/v1/accounts/:id/subscription`
- `GET  /saas/api/v1/accounts/:id/limits`
- `GET  /saas/api/v1/accounts/:id/plans`
- `POST /saas/webhooks/stripe`
- Super Admin: `resources :saas_plans`

### Frontend changes

- SaaS API client for billing endpoints
- Updated Vuex store with SaaS billing actions
- Rewritten billing page with plan cards and AI usage meter
- Removed CLOUD installation type restriction from billing routes

### Environment variables required

```env
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
```

---

## Phase 3 — LLM Provider Abstraction (LiteLLM Sidecar) ⬜

Run **LiteLLM** as a Docker sidecar exposing an OpenAI-compatible `/v1/chat/completions` endpoint, proxying to OpenAI, Anthropic, Gemini, and 100+ providers — including per-request BYOK.

### Planned steps

1. Add `litellm` service to `docker-compose.yml`
2. Create LiteLLM config YAML with model definitions
3. Build `saas/app/services/llm/client.rb` — thin Faraday wrapper
4. Stream responses via SSE through Action Cable
5. Token counting + Stripe metering integration

---

## Phase 4 — AI Agent Engine ⬜

### 4a — Core Agent Model

- `AiAgent` — type enum (rag/tool_calling/voice/hybrid), system_prompt, LLM config (JSONB)
- `AiAgentInbox` — join table Agent ↔ Inbox
- `KnowledgeBase` / `KnowledgeDocument` — documents with `embedding vector(1536)` via pgvector
- `AgentTool` — HTTP tools with Liquid template config

### 4b — RAG Pipeline

- Document chunking → LiteLLM embeddings → pgvector storage
- Cosine similarity search via `neighbor` gem → inject top-5 chunks into context
- URL crawling via Firecrawl

### 4c — Tool-Calling Workflow

- `Agent::Executor` — conversation turns with tool-calling loop (max 5 iterations)
- `Agent::ToolRunner` — HTTP tools with Liquid interpolation
- Built-in "Handoff to Human" tool

### 4d — Conversation Routing

- `AiAgentListener` — Wisper events → enqueue `AiAgentReplyJob` if inbox has active AI agent

### 4e — Voice Agents

- OpenAI Realtime API (WebSocket speech-in/speech-out)
- Twilio Voice → audio bridge → OpenAI Realtime
- Fallback: Whisper STT → text agent → OpenAI TTS

---

## Phase 5 — Agent Builder UI (Vue 3) ⬜

Route: `app/javascript/dashboard/routes/agentBuilder/`

| Page | Description |
|------|-------------|
| Agent List (`/agents`) | Cards with name, type, status, linked inboxes |
| Agent Create/Edit (`/agents/:id`) | Multi-tab wizard |
| Agent Analytics (`/agents/:id/analytics`) | Messages, handoff rate, token usage |

### Builder tabs

1. **Setup** — Name, avatar, type, LLM model, BYOK key, system prompt
2. **Knowledge Base** — File upload, URL crawl, document status
3. **Tools** — HTTP tool builder with Liquid templates + test
4. **Voice** — Voice selector, language, speed, interruption sensitivity
5. **Deploy** — Inbox selection, auto-reply toggle, active/paused
6. **Test Chat** — Embedded preview widget

---

## Phase 6 — Docker Compose Deployment ⬜

### Services

```yaml
services:
  rails:        # existing
  sidekiq:      # existing
  postgres:     # pgvector:pg16
  redis:        # existing
  litellm:      # ghcr.io/berriai/litellm:main (new)
  voice-bridge: # Twilio ↔ OpenAI Realtime bridge (new)
  nginx:        # reverse proxy + SSL (new)
```

### Deploy script

`./bin/deploy.sh` — pull images → `db:migrate` → `assets:precompile` → restart containers.

---

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `saas/` module instead of `enterprise/` | Clean IP boundary; safe upstream syncing |
| LiteLLM sidecar | One maintenance point, 100+ providers, BYOK per-request |
| Wisper listeners for agent routing | Follows existing Chatwoot patterns; no core modifications |
| Direct Stripe gem (not `pay` gem) | More control over subscription lifecycle and metered billing |
| pgvector for embeddings | Already in the stack; no extra infra |
| OpenAI Realtime API for voice | Native speech-in/speech-out with tool-calling |
