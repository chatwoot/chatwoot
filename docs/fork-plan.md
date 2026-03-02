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
| 3 | LiteLLM Sidecar | ✅ Complete | `7f20405` |
| 4 | AI Agent Engine | ✅ Complete | `7f20405` |
| 4a | Core Agent Models | ✅ Complete | `7f20405` |
| 4b | RAG Pipeline | ✅ Complete | `7f20405` |
| 4c | Tool-Calling Workflow | ✅ Complete | `7f20405` |
| 4d | Conversation Routing | ✅ Complete | `7f20405` |
| 4e | Voice Agents | ✅ Complete | `7f20405` |
| — | Voice Provider Audit | ✅ Complete | `7f20405` |
| — | Best Practices Review | ✅ Complete | — |
| 5 | Agent Builder UI | ✅ Complete | `8ccb3cb` |
| 6 | Docker Deployment | ✅ Complete | `80fb27e` |
| 7 | Testing & Quality | ✅ Complete | `26272d0` |
| 8 | Security & Auth Policies | ✅ Complete | `9e92e3e` |
| 9 | Production Hardening | ✅ Complete | `3795d1b` |

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

## Phase 3 — LLM Provider Abstraction (LiteLLM Sidecar) ✅

Run **LiteLLM** as a Docker sidecar exposing an OpenAI-compatible `/v1/chat/completions` endpoint, proxying to OpenAI, Anthropic, Gemini, and 100+ providers — including per-request BYOK.

### What was done

1. **Docker Compose** — Added `litellm` service (image `ghcr.io/berriai/litellm:main-latest`) to both `docker-compose.yaml` (dev) and `docker-compose.production.yaml` (prod). Exposes port 4000.
2. **LiteLLM config** — Created `config/litellm.yml` with model definitions for all models in `config/llm.yml`: OpenAI (gpt-4.1/5.x family), Anthropic (Claude 4.5), Google (Gemini 3), embeddings (text-embedding-3-small), and audio (whisper-1). Supports BYOK per-request.
3. **`Llm::Client`** — Built `saas/app/services/llm/client.rb`, a thin Net::HTTP wrapper with:
   - Blocking `chat()` and streaming `chat_stream()` (SSE parsing)
   - `embed()` for embeddings
   - `healthy?` and `models()` for proxy introspection
   - Custom error hierarchy: `RequestError`, `RateLimitError`, `AuthenticationError`, `TimeoutError`
   - BYOK support via `api_key` parameter
4. **ActionCable streaming** — Created `LlmChannel` (`app/channels/llm_channel.rb`) with:
   - Stream key scoped per account: `llm_stream_account_{id}`
   - Class-level broadcast helpers: `broadcast_chunk`, `broadcast_complete`, `broadcast_error`
   - Auth via pubsub_token + account membership check
5. **`LlmStreamJob`** — Sidekiq job (`saas/app/jobs/llm_stream_job.rb`) that:
   - Calls `Llm::Client#chat_stream` and broadcasts chunks via `LlmChannel`
   - Records token usage via `Saas::AiUsageRecord.record_usage!` on completion
   - Calculates cost using `credit_multiplier` from `config/llm.yml`
   - Resolves provider from model name via `LlmConstants::PROVIDER_PREFIXES`
6. **API controller** — Created `Saas::Api::V1::LlmController` with endpoints:
   - `POST completions` — blocking or streaming (returns `request_id` for ActionCable)
   - `POST embeddings` — vector embeddings
   - `GET models` — available models from config
   - `GET health` — LiteLLM proxy health check
   - Enforces `ai_usage_exceeded?` limit checks (returns 402 when quota exceeded)
7. **Routes** — Nested under SaaS accounts namespace:
   - `POST /saas/api/v1/accounts/:account_id/llm/completions`
   - `POST /saas/api/v1/accounts/:account_id/llm/embeddings`
   - `GET  /saas/api/v1/accounts/:account_id/llm/models`
   - `GET  /saas/api/v1/accounts/:account_id/llm/health`
8. **Environment variables** — Added `LITELLM_BASE_URL`, `LITELLM_MASTER_KEY`, `LITELLM_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY` to `.env`.

### Files changed

| File | Action |
|------|--------|
| `docker-compose.yaml` | Added `litellm` service |
| `docker-compose.production.yaml` | Added `litellm` service |
| `config/litellm.yml` | New — LiteLLM proxy config (14 models) |
| `saas/app/services/llm/client.rb` | New — HTTP client for LiteLLM proxy |
| `app/channels/llm_channel.rb` | New — ActionCable channel for SSE streaming |
| `saas/app/jobs/llm_stream_job.rb` | New — Background job for streaming + metering |
| `saas/app/controllers/saas/api/v1/llm_controller.rb` | New — API controller |
| `config/routes.rb` | Added LLM routes under SaaS namespace |
| `.env` | Added LiteLLM env vars |

---

## Phase 4 — AI Agent Engine ✅

### 4a — Core Agent Model ✅

- `AiAgent` — type enum (rag/tool_calling/voice/hybrid), system_prompt, LLM config (JSONB)
- `AiAgentInbox` — join table Agent ↔ Inbox
- `KnowledgeBase` / `KnowledgeDocument` — documents with `embedding vector(1536)` via pgvector
- `AgentTool` — HTTP tools with Liquid template config

**What was done:**
- 5 migrations: `create_ai_agents`, `create_ai_agent_inboxes`, `create_knowledge_bases`, `create_knowledge_documents` (with ivfflat vector index), `create_agent_tools`
- 5 models under `saas/app/models/saas/`: `AiAgent`, `AiAgentInbox`, `KnowledgeBase`, `KnowledgeDocument` (with `has_neighbors :embedding`), `AgentTool` (with `to_llm_tool` for OpenAI function-calling format + Liquid template rendering)
- Account associations: `has_many :ai_agents`, `has_many :knowledge_bases`, `has_many :agent_tools` (through)
- Inbox associations: `has_one :ai_agent_inbox`, `has_one :ai_agent` (through)
- Fixed `prepend_mod_with` pattern: use `prepended do` (not `included do`) for modules injected via `prepend`

### 4b — RAG Pipeline ✅

- Document chunking → LiteLLM embeddings → pgvector storage
- Cosine similarity search via `neighbor` gem → inject top-5 chunks into context
- URL crawling via Firecrawl

**What was done:**
- `Rag::TextChunker` — recursive character-based splitter with configurable chunk_size (1000) and overlap (200)
- `Rag::EmbeddingService` — batched embedding via `Llm::Client#embed`, stores as `KnowledgeDocument` records
- `Rag::SearchService` — semantic search across AI agent's knowledge bases, `build_context` formats results for LLM injection
- `Rag::DocumentIngestionJob` — full pipeline: resolve text → chunk → embed → store (Sidekiq `:low` queue)
- `Rag::UrlCrawler` — Firecrawl API if configured, otherwise Nokogiri fallback scraper

### 4c — Tool-Calling Workflow ✅

- `Agent::Executor` — conversation turns with tool-calling loop (max 5 iterations)
- `Agent::ToolRunner` — HTTP tools with Liquid interpolation
- Built-in "Handoff to Human" tool

**What was done:**
- `Agent::Executor` — multi-turn orchestrator: system prompt assembly + RAG context injection + tool-calling loop + usage tracking
- `Agent::ToolRunner` — executes HTTP tools (Liquid URL/body/headers), built-in tools, and `handoff_to_human` (unassigns + activity message)
- Handoff creates activity message and clears assignee on the conversation

### 4d — Conversation Routing ✅

- `AiAgentListener` — Wisper events → enqueue `AiAgentReplyJob` if inbox has active AI agent

**What was done:**
- `AiAgentListener` — listens to `message_created`, checks if inbox has active AI agent via `AiAgentInbox.active_agent_for`, enqueues `AiAgentReplyJob`
- `AiAgentReplyJob` — builds conversation history, runs `Agent::Executor`, posts outgoing reply with `ai_generated: true` content attribute
- Usage limit enforcement: posts system message when quota exceeded
- Registered in `AsyncDispatcher` via SaaS module prepend (`saas/app/dispatchers/saas/async_dispatcher.rb`)

### 4e — Voice Agents ✅

- Provider-agnostic voice architecture (OpenAI Realtime + ElevenLabs Conversational AI)
- Twilio Voice → audio bridge → configurable provider
- Fallback: STT → text agent → TTS (provider-agnostic)
- Native µ-law g711 audio format (no transcoding needed for Twilio)

**What was done:**

Provider abstraction layer:
- `Voice::Provider::Base` — abstract interface (connect!, send_audio, disconnect!, synthesize, transcribe, callbacks)
- `Voice::Provider::Openai` — OpenAI Realtime API via Faye::WebSocket (g711_ulaw, VAD, tool support, transcript saving)
- `Voice::Provider::Elevenlabs` — ElevenLabs Conversational AI WebSocket + TTS REST API (native µ-law, 5000+ voices)
- `Voice::Provider.for(ai_agent:)` — factory method, selects provider from `voice_config['provider']`

Core services:
- `Voice::RealtimeSession` — backward-compatible shim delegating to provider abstraction
- `Voice::TwilioBridge` — bridges Twilio Media Streams ↔ any Voice Provider (transmit-based for ActionCable)
- `Voice::FallbackPipeline` — provider-agnostic STT → Agent::Executor → TTS pipeline
- `VoiceRealtimeChannel` (ActionCable) — WebSocket endpoint for Twilio `<Stream>` TwiML, fixed Object#send override
- `Saas::Api::V1::Voice::TwilioController` — 3 endpoints with Twilio signature verification
- `Channel::Voice` model — phone_number, provider, provider_config (JSONB), Twilio client, signature verification
- AiAgent multi-provider voice helpers: `voice_provider`, `voice_id`, `realtime_model`, `realtime_capable?`
- `config/llm.yml` — ElevenLabs provider + models (eleven_turbo_v2_5, eleven_multilingual_v2)
- `config/litellm.yml` — TTS models (tts-1, tts-1-hd) added
- `faye-websocket` gem added (replaces missing websocket-client-simple)

Bug fixes from deep audit:
- Fixed `aproviders:` typo in llm.yml
- Created missing `Channel::Voice` model class
- Fixed audio format mismatch (pcm16 → g711_ulaw for Twilio compatibility)
- Added connect timeout (replaces infinite busy-wait sleep loop)
- Added thread-safety via Mutex in WebSocket operations
- Fixed Object#send override in VoiceRealtimeChannel
- Added Twilio signature verification to controller
- Fixed route helper names (use explicit URLs instead of broken _url helpers)
- Fixed file handle leak in transcribe (File.open block form)
- Removed dead code (@llm_client, unused constants)
- Added HTTP error handling in provider methods

---

## Voice Provider Audit ✅

Deep audit of the voice implementation revealed 12+ bugs. All fixed in commit `7f20405`.

### Bugs found & fixed

| # | Issue | Fix |
|---|-------|-----|
| 1 | `aproviders:` typo in `config/llm.yml` | Fixed to `providers:` |
| 2 | Missing `Channel::Voice` model class | Created `saas/app/models/channel/voice.rb` |
| 3 | Audio format mismatch (`pcm16` sent to Twilio) | Changed to `g711_ulaw` native µ-law |
| 4 | Infinite busy-wait `sleep` loop waiting for WebSocket | Added `connect_timeout` with `Timeout.timeout` |
| 5 | Thread-safety issues in WebSocket operations | Added `Mutex` for `@ws` access |
| 6 | `Object#send` override in `VoiceRealtimeChannel` | Renamed to `transmit_audio` |
| 7 | Missing Twilio signature verification | Added `Twilio::Security::RequestValidator` to controller |
| 8 | Broken route `_url` helpers | Use explicit URL strings |
| 9 | File handle leak in `transcribe` | Use `File.open` block form |
| 10 | Dead code (`@llm_client`, unused constants) | Removed |
| 11 | Missing HTTP error handling in provider methods | Added `Net::HTTPSuccess` checks |
| 12 | ElevenLabs missing native µ-law output format | Set `output_format: 'ulaw_8000'` |

---

## Best Practices Review ✅

Cross-referenced all implementations against official API docs (OpenAI Realtime GA, Stripe Webhooks, Stripe Billing). Found and fixed 15 issues.

### OpenAI Realtime API — GA migration

| # | Issue | Fix |
|---|-------|-----|
| 1 | Used beta flat `voice`/`input_audio_format` params | Migrated to GA nested `audio {}` config |
| 2 | Sent deprecated `OpenAI-Beta: realtime=v1` header | Removed header |
| 3 | Only handled beta event names | Added dual event handling (beta + GA names) |
| 4 | Missing noise reduction for phone calls | Added `noise_reduction: { type: 'far_field' }` |
| 5 | VAD type hardcoded to `server_vad` | Made configurable (`server_vad` or `semantic_vad`) |
| 6 | Transcription used `whisper-1` | Updated to `gpt-4o-transcribe` |
| 7 | Default voice was `alloy` | Updated to `coral` |
| 8 | Missing GA realtime models in config | Added `gpt-realtime` and `gpt-realtime-mini` to `config/llm.yml` |

### Stripe best practices

| # | Issue | Fix |
|---|-------|-----|
| 9 | Webhook processed synchronously (blocking Stripe) | Returns 200 immediately, processes async via `Saas::StripeWebhookJob` |
| 10 | No idempotency protection | Added `Rails.cache`-based idempotency for webhook events |
| 11 | Unsigned webhooks accepted in production | Added production guard rejecting unsigned webhooks |
| 12 | Hardcoded `payment_method_types: ['card']` | Removed to allow Stripe's dynamic payment methods |

### Other fixes

| # | Issue | Fix |
|---|-------|-----|
| 13 | `AiAgentReplyJob` used wrong param names | Fixed `input_tokens`/`output_tokens` → `tokens_input`/`tokens_output` |
| 14 | `AiAgentReplyJob` missing `provider:` param | Added `provider:` to `record_usage!` call |
| 15 | LLM controller re-parsed YAML config on every request | Added `Rails.cache.fetch` for production config caching |

### Files changed

| File | Change |
|------|--------|
| `saas/app/services/voice/provider/openai.rb` | GA format migration, dual events, noise reduction, semantic VAD |
| `saas/app/jobs/ai_agent_reply_job.rb` | Fixed param names + added `provider:` |
| `saas/app/controllers/saas/webhooks/stripe_controller.rb` | Async processing via job, production signature guard |
| `saas/app/jobs/saas/stripe_webhook_job.rb` | **New** — background webhook processing with idempotency |
| `saas/app/controllers/saas/api/v1/llm_controller.rb` | Config caching in production |
| `saas/app/services/saas/stripe_service.rb` | Removed hardcoded payment methods |
| `config/llm.yml` | Added GA realtime models, updated defaults |

---

## Phase 5 — Agent Builder UI (Vue 3) ✅

Route: `app/javascript/dashboard/routes/dashboard/aiAgents/`

### What was done

1. **Backend API** — 5 SaaS controllers under `saas/app/controllers/saas/api/v1/`:
   - `AiAgentsController` — Full CRUD for AI agents with detailed JSON serialization
   - `KnowledgeBasesController` — CRUD nested under ai_agents
   - `KnowledgeDocumentsController` — Create/destroy with auto-enqueue `Rag::DocumentIngestionJob`
   - `AgentToolsController` — CRUD nested under ai_agents
   - `AiAgentInboxesController` — Create/update/destroy for inbox connections

2. **API Routes** — Nested resources under `/saas/api/v1/accounts/:account_id/ai_agents`

3. **Frontend API Client** — `api/saas/aiAgents.js` extending `ApiClient` with `{ accountScoped: true, saas: true }`

4. **Vuex Store** — `store/modules/aiAgents.js` with state, getters, CRUD actions, and mutations using `MutationHelpers`

5. **Vue Components** — Full Agent Builder UI:
   - **Agent List Page** — Grid of agent cards with name, type, status, counts
   - **Agent Detail Page** — Tabbed layout with 5 tabs (Setup, Knowledge, Tools, Voice, Deploy)
   - **Create/Edit Agent Dialog** — Modal form with name, description, type, model, system prompt
   - **Delete Agent Dialog** — Confirmation dialog with Vuex delete action
   - **Setup Tab** — Full agent settings form (name, description, type, model, system prompt, temperature)
   - **Knowledge Tab** — CRUD for knowledge bases + document management (URL/text/file)
   - **Tools Tab** — CRUD for HTTP/handoff/built-in tools with method, URL, headers, body template
   - **Voice Tab** — Provider, voice ID, language, speed, greeting, interruption sensitivity, realtime model
   - **Deploy Tab** — Connect/disconnect inboxes, auto-reply toggle, status indicators

6. **Frontend Routes** — `aiAgents.routes.js` with parent wrapper + lazy-loaded child routes

7. **Sidebar Navigation** — "AI Agents" entry with bot icon added after Captain section

8. **i18n** — Comprehensive English translations (`aiAgents.json`) registered in locale index

| Page | Description |
|------|-------------|
| Agent List (`/ai-agents`) | Cards with name, type, status, linked inboxes |
| Agent Detail (`/ai-agents/:id/setup`) | Multi-tab settings page |
| Agent Detail (`/ai-agents/:id/knowledge`) | Knowledge base & document management |
| Agent Detail (`/ai-agents/:id/tools`) | Tool CRUD with HTTP config |
| Agent Detail (`/ai-agents/:id/voice`) | Voice configuration |
| Agent Detail (`/ai-agents/:id/deploy`) | Inbox connections |

### Builder tabs

1. **Setup** — Name, avatar, type, LLM model, BYOK key, system prompt
2. **Knowledge Base** — File upload, URL crawl, document status
3. **Tools** — HTTP tool builder with Liquid templates + test
4. **Voice** — Voice selector, language, speed, interruption sensitivity
5. **Deploy** — Inbox selection, auto-reply toggle, active/paused
6. **Test Chat** — Embedded preview widget

---

## Phase 6 — Docker Compose Deployment (Traefik) ✅

**Commit:** `80fb27e16`

Production-ready Docker Compose stack with Traefik v3 reverse proxy, Let's Encrypt SSL, health checks, resource limits, and deploy/backup tooling.

### Architecture

```
┌─────────────┐     ┌──────────────────────────────────────────┐
│  Internet   │────▶│  Traefik v3 (:80 → :443 redirect)        │
│             │◀────│  Let's Encrypt ACME auto-renewal         │
└─────────────┘     └─┬──────────────────────────────────────┬─┘
                      │ web network                         │
              ┌───────▼───────┐                             │
              │  Rails/Puma   │                              │
              │  :3000        │                              │
              │  (+ /cable WS)│                              │
              └───────┬───────┘                              │
                      │ internal network                    │
           ┌──────────┼──────────┬──────────────┐           │
           ▼          ▼          ▼              ▼           │
      ┌─────────┐ ┌────────┐ ┌────────┐ ┌────────────┐     │
      │Postgres │ │ Redis  │ │Sidekiq │ │  LiteLLM   │     │
      │ pg17    │ │7-alpine│ │        │ │  :4000     │     │
      │pgvector │ │AOF+RDB │ │        │ │ (internal) │     │
      └─────────┘ └────────┘ └────────┘ └────────────┘
```

### Services

| Service | Image | Exposed | Memory Limit |
|---------|-------|---------|--------------|
| traefik | `traefik:v3.3` | :80, :443 | 128M |
| rails | AirysChat image | via Traefik | 1G |
| sidekiq | AirysChat image | — | 1G |
| postgres | `pgvector/pgvector:pg17` | — | 512M |
| redis | `redis:7-alpine` | — | 300M |
| litellm | `ghcr.io/berriai/litellm:main-latest` | — (internal only) | 512M |

### What was done

1. **`docker-compose.production.yaml`** — Full rewrite:
   - Traefik v3 as entrypoint with automatic HTTPS via Let's Encrypt ACME
   - Docker labels for routing (no separate nginx config to maintain)
   - Two networks: `web` (Traefik ↔ Rails) and `internal` (all backend services)
   - Health checks on all services (pg_isready, redis-cli ping, wget rails, curl litellm)
   - `depends_on` with `condition: service_healthy` for startup ordering
   - `deploy.resources.limits.memory` on every service
   - `restart: unless-stopped` across the board
   - LiteLLM has NO Traefik labels → not exposed to internet
   - pgvector upgraded from pg16 → pg17
   - Redis upgraded to `redis:7-alpine` with AOF persistence + 256MB maxmemory

2. **Traefik static config** — `deployment/traefik/traefik.yml`:
   - Entrypoints: `:80` (auto-redirects to HTTPS), `:443` (TLS)
   - Let's Encrypt ACME `tlsChallenge` cert resolver
   - Docker provider with `exposedByDefault: false` (opt-in via labels)
   - File provider for dynamic middleware config
   - JSON access logging (4xx/5xx only)

3. **Traefik dynamic middleware** — `deployment/traefik/dynamic/middleware.yml`:
   - `security-headers` — XSS filter, nosniff, HSTS, frame options, referrer policy, permissions policy
   - `gzip-compress` — compression (excludes `text/event-stream` for SSE)
   - `dashboard-auth` — basicAuth for Traefik dashboard
   - `rate-limit` — global fallback rate limiter (100 req/s, burst 200)

4. **`.env.production.example`** — Complete production env template:
   - Domain + ACME email for Traefik/SSL
   - Rails core (SECRET_KEY_BASE, FORCE_SSL, WEB_CONCURRENCY)
   - Active Record encryption keys (for AgentTool auth_token)
   - PostgreSQL + Redis credentials
   - SMTP/mailer config
   - Stripe, LiteLLM, OpenAI/Anthropic/Gemini keys
   - Twilio, ElevenLabs, Firecrawl (optional)
   - Rate limiting, storage, push notifications, Sentry

5. **`bin/deploy.sh`** — Zero-downtime deploy script:
   - `--skip-pull` and `--skip-migrate` flags
   - Pulls latest images, runs `db:migrate` in disposable container
   - Rolling restart: sidekiq first, then rails
   - Post-deploy health check on all 4 services

6. **`bin/backup.sh`** — Automated backup script:
   - PostgreSQL `pg_dump` in compressed custom format (-Fc)
   - Redis BGSAVE + RDB copy
   - Optional S3 upload with `--s3 BUCKET_NAME`
   - Auto-cleanup: keeps last 7 local backups

### Files changed

| File | Action |
|------|--------|
| `docker-compose.production.yaml` | Rewritten — Traefik, health checks, resource limits, networks |
| `deployment/traefik/traefik.yml` | New — static Traefik config |
| `deployment/traefik/dynamic/middleware.yml` | New — security headers, compression, auth |
| `.env.production.example` | New — complete production env template |
| `bin/deploy.sh` | New — zero-downtime deploy script |
| `bin/backup.sh` | New — PostgreSQL + Redis backup with S3 optional upload |

---

## Phase 7 — Testing & Quality ✅

**Commit:** `26272d086` — `test: add specs for policies, SSRF, models, services, and jobs`
**17 files changed, +783 / -9 lines — 73 examples, 0 failures**

### What was done

1. **FactoryBot factories** — 5 factories under `spec/factories/saas/`:
   - `ai_agents` — traits: `:tool_calling`, `:voice`, `:hybrid`, `:paused`, `:archived`
   - `agent_tools` — traits: `:inactive`, `:with_auth`, `:handoff`, `:built_in`
   - `knowledge_bases` — traits: `:processing`, `:error`
   - `knowledge_documents` — traits: `:pending`, `:processing`, `:error`, `:from_url`
   - `ai_agent_inboxes` — traits: `:paused`

2. **Pundit policy specs** — 6 policy specs (20 examples) under `spec/policies/saas/`:
   - `AiAgentPolicy` — index/show allow both admin & agent; CUD admin-only
   - `AgentToolPolicy` — index allows both roles; CUD admin-only
   - `KnowledgeBasePolicy` — index/show both roles; CUD admin-only
   - `KnowledgeDocumentPolicy` — create/destroy admin-only
   - `AiAgentInboxPolicy` — CUD admin-only
   - `LlmPolicy` — completions/embeddings/models both roles; health admin-only

3. **SSRF validator spec** — `spec/lib/url_ssrf_validator_spec.rb` (21 examples):
   - Blocked schemes (file://, ftp://, gopher://)
   - Private IP ranges (127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16, 0.0.0.0, ::1)
   - DNS rebinding protection (hostnames resolving to private IPs)
   - Unresolvable hostnames, missing hosts
   - `safe?` convenience method

4. **AgentTool model spec** — `spec/models/saas/agent_tool_spec.rb` (17 examples):
   - Associations (`belongs_to :ai_agent`, `belongs_to :account`)
   - Validations (presence, length)
   - URL template internal-address blocking (localhost, 127.0.0.1, metadata, .local)
   - `to_llm_tool` OpenAI function-calling format
   - `rendered_url` / `rendered_body` Liquid template rendering

5. **ToolRunner service spec** — `spec/services/agent/tool_runner_spec.rb` (8 examples):
   - Handoff tool (conversation unassignment + activity message)
   - Unknown tool error handling
   - HTTP tool execution (WebMock with DNS stub)
   - SSRF blocking (cloud metadata, DNS rebinding)
   - Network error handling
   - Response truncation (4000 char limit)

6. **AiAgentReplyJob spec** — `spec/jobs/ai_agent_reply_job_spec.rb` (7 examples):
   - `retry_on` RateLimitError / TimeoutError (behavioral tests via `assert_enqueued_jobs`)
   - `discard_on` ActiveRecord::RecordNotFound
   - Outgoing message creation with `ai_generated` content attribute
   - Handoff skips reply
   - Error tracking + re-raise

### Bugs discovered and fixed during testing

| # | Issue | Fix |
|---|-------|-----|
| 1 | SSRF validator checked host before scheme → `file:///etc/passwd` errored as "missing host" | Reordered: scheme validation runs first |
| 2 | `ToolRunner#handle_handoff` created activity message without `inbox_id` → `RecordInvalid` | Added `inbox_id: conversation.inbox_id` |

---

## Phase 8 — Security & Authorization Policies ✅

**Commit:** `9e92e3efd` — `feat(security): add Pundit policies, SSRF protection, and rate limiting`

### What was done

1. **Pundit policies** — 6 policies under `saas/app/policies/saas/`:
   - `AiAgentPolicy` — index/show for all roles; create/update/destroy admin-only
   - `AgentToolPolicy` — index for all roles; CUD admin-only
   - `KnowledgeBasePolicy` — index/show for all roles; CUD admin-only
   - `KnowledgeDocumentPolicy` — create/destroy admin-only
   - `AiAgentInboxPolicy` — CUD admin-only
   - `LlmPolicy` — completions/embeddings/models for all roles; health admin-only
   - All policies use `{ user:, account:, account_user: }` context hash pattern

2. **Controller authorization** — Added `before_action :authorize_*` to all 6 SaaS controllers:
   - `AiAgentsController`, `AgentToolsController`, `KnowledgeBasesController`
   - `KnowledgeDocumentsController`, `AiAgentInboxesController`, `LlmController`

3. **SSRF protection** — `saas/lib/url_ssrf_validator.rb`:
   - Blocks private IP ranges: RFC 1918, loopback, link-local, metadata, multicast, reserved
   - Blocks IPv6 private ranges: `::1`, `fc00::/7`, `fe80::/10`
   - DNS rebinding protection: resolves hostnames and checks all resolved IPs
   - Blocked URL schemes: `file://`, `ftp://`, `gopher://`
   - Integrated into `Agent::ToolRunner` (runtime) and `AgentTool` model (validation)

4. **Rate limiting** — `config/initializers/rack_attack.rb`:
   - LLM completions: 60 requests/minute per account (configurable via `RATE_LIMIT_LLM_COMPLETIONS`)
   - LLM embeddings: 120 requests/minute per account (configurable via `RATE_LIMIT_LLM_EMBEDDINGS`)
   - Returns 429 with `Retry-After` header

5. **Model-level URL validation** — `AgentTool#url_template_not_obviously_internal`:
   - Rejects `localhost`, `127.x.x.x`, `169.254.169.254`, `metadata.google.internal`, `.local` domains
   - Rejects non-HTTP schemes (ftp, file, gopher)
   - Only applies to `http` tool_type with non-blank `url_template`

### Files changed

| File | Action |
|------|--------|
| `saas/app/policies/saas/ai_agent_policy.rb` | New — Pundit policy |
| `saas/app/policies/saas/agent_tool_policy.rb` | New — Pundit policy |
| `saas/app/policies/saas/knowledge_base_policy.rb` | New — Pundit policy |
| `saas/app/policies/saas/knowledge_document_policy.rb` | New — Pundit policy |
| `saas/app/policies/saas/ai_agent_inbox_policy.rb` | New — Pundit policy |
| `saas/app/policies/saas/llm_policy.rb` | New — Pundit policy |
| `saas/lib/url_ssrf_validator.rb` | New — SSRF validation module |
| `saas/app/models/saas/agent_tool.rb` | Added URL validation |
| `saas/app/services/agent/tool_runner.rb` | Added SSRF check before HTTP calls |
| `config/initializers/rack_attack.rb` | Added LLM rate limiting |

---

## Phase 9 — Production Hardening ✅

**Commit:** `3795d1bb0` — `feat(hardening): structured logging, job resilience, health checks, encryption, indexes`

### What was done

1. **Structured logging** — `Saas::Api::V1::LlmController`:
   - `[SaaS::LLM]` tagged log lines with `account_id`, `model`, `tokens`, `duration_ms`, `status`
   - Covers completions, embeddings, streaming, and error paths

2. **Thread-safe LLM config** — Fixed `@@llm_config` class variable (shared across threads):
   - Replaced with `Mutex` + `self.class.instance_variable_get/set(:@_llm_config)`
   - Thread-safe lazy initialization with double-checked locking

3. **Expanded health endpoint** — `GET /llm/health`:
   - LiteLLM proxy check (existing)
   - Database connectivity (`ActiveRecord::Base.connection.execute('SELECT 1')`)
   - pgvector extension (`SELECT extversion FROM pg_extension WHERE extname='vector'`)
   - Redis connectivity (`$velma.with { |conn| conn.ping }`)
   - Returns per-component status JSON

4. **Job resilience** — `retry_on` / `discard_on` on all 4 SaaS background jobs:
   - `AiAgentReplyJob` — retry on `RateLimitError` (5 attempts, polynomially_longer) + `TimeoutError` (3 attempts, 10s); discard on `RecordNotFound`
   - `LlmStreamJob` — `sidekiq_options retry: 0`; discard on `RecordNotFound`
   - `Rag::DocumentIngestionJob` — retry on `RateLimitError` (5 attempts) + `TimeoutError` (3 attempts); discard on `RecordNotFound`
   - `Saas::StripeWebhookJob` — retry on `APIConnectionError` + `RateLimitError` (5 attempts each); discard on `JSON::ParserError`

5. **Auth token encryption** — `Saas::AgentTool`:
   - `encrypts :auth_token` (guarded by `Chatwoot.encryption_configured?`)
   - Requires `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`, `_DETERMINISTIC_KEY`, `_KEY_DERIVATION_SALT`

6. **Missing database indexes** — Migration `20260302000006_add_missing_indexes_to_saas_tables`:
   - `ai_agent_inboxes.inbox_id` — fast inbox → agent lookup
   - `knowledge_documents.knowledge_base_id` — document listing
   - `agent_tools.ai_agent_id` — tool loading per agent
   - `ai_usage_records.(account_id, recorded_on)` — usage aggregation queries

7. **Rate limit documentation** — `.env.example`:
   - `RATE_LIMIT_LLM_COMPLETIONS` (default: 60/min)
   - `RATE_LIMIT_LLM_EMBEDDINGS` (default: 120/min)

### Files changed

| File | Action |
|------|--------|
| `saas/app/controllers/saas/api/v1/llm_controller.rb` | Structured logging, thread-safe config, expanded health |
| `saas/app/jobs/ai_agent_reply_job.rb` | Added retry_on / discard_on |
| `saas/app/jobs/llm_stream_job.rb` | Added sidekiq_options retry: 0, discard_on |
| `saas/app/jobs/rag/document_ingestion_job.rb` | Added retry_on / discard_on |
| `saas/app/jobs/saas/stripe_webhook_job.rb` | Added retry_on / discard_on |
| `saas/app/models/saas/agent_tool.rb` | Added `encrypts :auth_token` |
| `db/migrate/20260302000006_add_missing_indexes_to_saas_tables.rb` | New — 4 indexes |
| `.env.example` | Documented rate limit env vars |

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
