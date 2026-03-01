Research Chatwoot architecture



Fetched 3 resources



Fetched https://github.com/chatwoot/chatwoot/blob/develop/Gemfile



Fetched https://github.com/chatwoot/chatwoot/tree/develop/app/javascript



Fetched https://github.com/chatwoot/chatwoot/blob/develop/package.json



Fetched https://www.chatwoot.com/docs/self-hosted



Fetched https://github.com/chatwoot/chatwoot/blob/develop/docker-compose.yaml



Fetched https://raw.githubusercontent.com/chatwoot/chatwoot/develop/package.json



Fetched https://developers.chatwoot.com/self-hosted/



Fetched https://raw.githubusercontent.com/chatwoot/chatwoot/develop/docker-compose.yaml



Fetched https://github.com/chatwoot/chatwoot/tree/develop/enterprise



Fetched https://github.com/chatwoot/chatwoot/tree/develop/enterprise/app



Fetched https://github.com/chatwoot/chatwoot/tree/develop/app/controllers



Fetched https://chwt.app/captain-docs



Fetched https://www.chatwoot.com/hc/user-guide/en/categories/captain



Fetched https://github.com/chatwoot/chatwoot/tree/develop/theme



Fetched https://github.com/chatwoot/chatwoot/tree/develop/app/fields



Fetched https://raw.githubusercontent.com/chatwoot/chatwoot/develop/theme/colors.js



Fetched https://github.com/chatwoot/chatwoot/tree/develop/app/models



Fetched https://github.com/chatwoot/chatwoot/tree/develop/app/controllers/api

Great research. Let me ask a few focused questions before drafting the plan, since some decisions meaningfully affect the architecture. 

Asked 4 questions (Agent Types, LLM Provider, Billing, Deployment)

All four agent types, multi-provider with BYOK, hybrid billing, Docker Compose. Let me draft the full plan now.

---

## Plan: Fork Chatwoot into a Multi-Tenant AI-Agent SaaS

**TL;DR** — Fork the MIT core of Chatwoot (Rails 7.1 + Vue 3 + pgvector + Redis + Sidekiq). Avoid touching the proprietary `enterprise/` directory; replace it with your own `saas/` module. Add Stripe billing (hybrid base plan + metered AI usage via the `pay` gem), a LiteLLM Python sidecar to abstract all LLM providers, a custom AI Agent engine (RAG + tool-calling + voice), and a visual Agent Builder UI built in Vue 3 inside the existing dashboard. Users create and deploy agents to any Chatwoot inbox without writing code. Deployed as Docker Compose on a single VPS.

---

### Phase 0 — Fork & Baseline Setup

1. Fork `chatwoot/chatwoot` into your own org (e.g. `yourorg/yoursaas`). Keep upstream as a remote (`git remote add upstream`) to pull security patches.
2. Remove the `enterprise/` directory entirely and replace references to it with your own `saas/` module directory, mirroring the same autoload path convention Rails uses there.
3. Update `config/application.rb` to eagerly load `saas/` instead of `enterprise/`.
4. Add a `UPSTREAM_SYNC_BRANCH` CI job that periodically rebases `upstream/develop` security-only patches.

---

### Phase 1 — Custom Branding

1. **Color tokens** — Replace the brand blue (`#2781F6`) with your brand color in theme/colors.js. All Tailwind classes (`n.brand`) cascade automatically via CSS custom properties.
2. **Logo + favicon** — Replace assets in `app/assets/images/` (logo, favicon, email header image). There are roughly 5–8 files to swap.
3. **Product name** — Set `INSTALLATION_NAME=YourBrand` in `.env`. This env var is already propagated through UI copy, email templates, and tooltips.
4. **Inter font** — Already in the stack; optionally swap to your brand font in `theme/` and `app/assets/fonts/`.
5. **Widget** — The embeddable widget in `app/javascript/widget/` already supports per-inbox custom colors; no changes needed unless you want a white-labeled domain (then configure `APP_DOMAIN` env var).
6. **Email templates** — Located in `app/views/devise/mailer/` and `app/mailers/`. Update header logo, footer copy, colors.

---

### Phase 2 — Stripe Billing (Hybrid: Base Plan + AI Metered Overage)

**Data model additions** (`saas/app/models/`)

- `Plan` — name, price, Stripe price ID, limits (agents, inboxes, seats, monthly AI credits included)
- `Subscription` — belongs to `Account`; Stripe subscription ID, current plan, status, current period dates
- `AiUsageRecord` — belongs to `Account`; token counts, provider, model, cost, timestamp (for metering)

**Backend steps**

1. Add [`pay` gem](https://github.com/pay-rails/pay) to `Gemfile` — it wraps Stripe (and others) for subscriptions, webhooks, and one-off charges. Add `stripe` gem alongside it.
2. Create a `saas/app/controllers/saas/subscriptions_controller.rb` — serves the billing portal page, creates Stripe Checkout sessions, handles plan upgrades/downgrades.
3. Create a Stripe webhook controller at `saas/app/controllers/saas/webhooks/stripe_controller.rb` — handles `invoice.paid`, `invoice.payment_failed`, `customer.subscription.updated/deleted`. Flip `Subscription#status` accordingly.
4. Gate features in `app/policies/` (Pundit) using a `PlanPolicy` — checks `account.subscription.plan.limits` before allowing agent creation, inbox creation, seat additions, etc.
5. **Metered billing** — after every AI action (a token-consuming LLM call), create a Stripe usage record via `stripe.billing_meter_events.create`. Store in `AiUsageRecord` for local dashboards. End-of-month Stripe issues the overage invoice automatically.
6. Add a **Billing page** in the Vue 3 dashboard (`app/javascript/dashboard/routes/billing/`) — shows current plan, usage bar (credits used vs. included), upgrade/downgrade buttons, invoice history (Stripe Customer Portal embed).
7. **Super Admin** — extend `/super_admin` (Administrate) with pages for Plans CRUD and per-account subscription override.
8. **Onboarding flow** — after account registration, redirect to a plan selection page before reaching the dashboard. Stripe Checkout handles card capture.

---

### Phase 3 — LLM Provider Abstraction (LiteLLM Sidecar)

Rather than writing per-provider adapters in Ruby, run **LiteLLM** as a Docker sidecar. It exposes an OpenAI-compatible `/v1/chat/completions` endpoint and proxies to OpenAI, Anthropic, Gemini, and 100+ other providers — including per-request BYOK.

1. Add `litellm` service to `docker-compose.yml` — image `ghcr.io/berriai/litellm:main`, config YAML mounts, exposes port `4000` internally.
2. Create a LiteLLM config YAML (`config/litellm_config.yaml`) defining models: `gpt-4o`, `claude-3-5-sonnet`, `gemini-2.0-flash`, plus a passthrough model for BYOK.
3. Build a `saas/app/services/llm/client.rb` in Rails — a thin wrapper around Faraday that POSTs to `http://litellm:4000/v1/chat/completions`. Injects `api_key` header from the agent's stored credentials (your master key or user's BYOK key, encrypted with `attr_encrypted`).
4. Stream responses via SSE — LiteLLM supports `stream: true`; Rails forwards the SSE stream through Action Cable to the Vue dashboard for real-time visual feedback.
5. A `saas/app/services/llm/token_counter.rb` parses the `usage` field from every response and writes an `AiUsageRecord` row + fires the Stripe metering event.

---

### Phase 4 — AI Agent Engine

#### 4a — Core Agent Model

New models in `saas/app/models/`:
- `AiAgent` — belongs to `Account`; name, description, avatar, `agent_type` enum (`rag | tool_calling | voice | hybrid`), system_prompt, LLM provider + model config (JSONB), voice config (JSONB)
- `AiAgentInbox` — join table linking `AiAgent` ↔ `Inbox` (an agent can cover multiple inboxes)
- `KnowledgeBase` — belongs to `AiAgent`; a collection that groups documents
- `KnowledgeDocument` — belongs to `KnowledgeBase`; source type (`pdf | url | text`), raw content, processed status, `embedding vector(1536)` (pgvector column — already supported by the DB)
- `AgentTool` — belongs to `AiAgent`; name, description, `tool_type` (`http_request | webhook | handoff_to_human`), config JSONB (URL, method, headers template, body template, output mapping)

#### 4b — RAG Pipeline

1. `saas/app/jobs/embed_document_job.rb` — Sidekiq job: chunk document → call LiteLLM `/v1/embeddings` → store chunks as `KnowledgeDocument` rows with `pgvector` embedding columns.
2. `saas/app/services/rag/retriever.rb` — at query time, embed the user message, run `KnowledgeDocument.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(5)` (using the `neighbor` gem, already in the `searchkick` ecosystem).
3. Inject retrieved chunks into the LLM system context before the user message.
4. URL crawling via **Firecrawl** (already referenced in the codebase) — `saas/app/services/rag/crawl_url_service.rb`.

#### 4c — Tool-Calling Workflow Engine

1. `saas/app/services/agent/executor.rb` — orchestrates a conversation turn:
   - Build messages array (system prompt + RAG context + conversation history)
   - Pass tools as OpenAI-format `tools` array to LiteLLM
   - If response contains `tool_calls` → execute the matching `AgentTool` (HTTP request, etc.) → append result → loop back to LLM (max 5 iterations)
   - When LLM returns a plain text message → send as a Chatwoot message via the existing `Messages::Create` service
2. `saas/app/services/agent/tool_runner.rb` — executes individual tools; supports Liquid template interpolation (already a gem in the stack) for dynamic headers/body using conversation variables.
3. **Handoff to human** — a special built-in tool that sets `conversation.assignee` to a team/agent and stops the agent loop.

#### 4d — Conversation Routing Hook

Extend the existing `app/listeners/` Wisper pattern:
- `saas/app/listeners/ai_agent_listener.rb` — subscribes to `conversation.created` and `message.created` events; if the conversation's inbox has an `AiAgentInbox` and the agent is active, enqueue `saas/app/jobs/ai_agent_reply_job.rb`.
- This cleanly replaces the legacy `AgentBot` framework without touching core files.

#### 4e — Voice Agents

1. For **real-time voice**, integrate **OpenAI Realtime API** (WebSocket, supports speech-in/speech-out with tool calling). Add a `saas/app/services/voice/realtime_session.rb` service.
2. For **phone channels**, wire Twilio Voice webhooks into `saas/app/controllers/webhooks/twilio_voice_controller.rb` — streams audio to/from OpenAI Realtime API via a media bridge (a small Node.js or Ruby WebSocket bridge in Docker).
3. Voice config per agent stores: voice name, language, interruption threshold, silence timeout.
4. Fallback: if OpenAI Realtime unavailable, use STT (Whisper via LiteLLM) → text agent → TTS (OpenAI TTS) pipeline.

---

### Phase 5 — Agent Builder UI (Vue 3)

New route module at `app/javascript/dashboard/routes/agentBuilder/`:

**Pages / Views:**

| Page | What it contains |
|---|---|
| **Agent List** (`/agents`) | Cards for all agents in the account: name, type, status, linked inboxes, quick stats |
| **Agent Create/Edit** (`/agents/:id`) | Multi-tab wizard (see below) |
| **Agent Analytics** (`/agents/:id/analytics`) | Messages handled, handoff rate, token usage, user satisfaction |

**Agent Builder tabs (inside the wizard):**

1. **Setup** — Name, avatar upload, type selector (RAG / Tool-Calling / Voice / Hybrid), LLM model picker (dropdown of available models from `/api/llm/models`), BYOK API key input (encrypted, stored per-agent), system prompt textarea with variable hints.
2. **Knowledge Base** — File upload (PDF, DOCX, TXT), URL input with crawl depth selector, plain text paste. Table of indexed documents with status (queued / indexed / failed), chunk count, delete button.
3. **Tools** — "Add Tool" button opens a drawer: tool name/description → HTTP method + URL → headers key-value editor → body template (Liquid) → response JSON path mapping → test button (live HTTP call preview). Drag-to-reorder. Built-in tools: "Handoff to Human" toggle.
4. **Voice** (shown only when voice type selected) — Voice selector, language, speed, interruption sensitivity slider, test audio playback.
5. **Deploy** — Multi-select of inboxes to attach this agent to. Toggle: auto-reply vs. wait for escalation. Active/Paused status toggle.
6. **Test Chat** — A floating preview widget (uses the same embeddable widget component) that lets you chat with the agent in real-time before deploying.

**API endpoints needed** (`saas/app/controllers/api/v1/`):
- `AiAgentsController` — CRUD for agents
- `KnowledgeBasesController` — upload documents, list, delete, re-index
- `AgentToolsController` — CRUD for tools, plus a `POST /test` action
- `LlmController` — `GET /models` returns available models for the account's plan

---

### Phase 6 — Docker Compose Deployment

Update `docker-compose.yml` to include:

```
services:
  rails          → existing
  sidekiq        → existing
  postgres       → pgvector:pg16 (already correct)
  redis          → existing
  litellm        → ghcr.io/berriai/litellm:main (new)
  voice-bridge   → custom Node.js WebSocket bridge for Twilio ↔ OpenAI Realtime (new)
  nginx          → reverse proxy (SSL termination, static assets)
```

Key environment variables to document in `.env.example`:
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_PUBLISHABLE_KEY`
- `LITELLM_MASTER_KEY` (your OpenAI key for platform-level calls)
- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GOOGLE_API_KEY` (platform defaults)
- `INSTALLATION_NAME`, `APP_DOMAIN`
- `FIRECRAWL_API_KEY`

One-command deploy script: `./bin/deploy.sh` — pulls images, runs `db:migrate`, `assets:precompile`, restarts containers.

---

### Verification

- **Billing**: Create a test account → select a paid plan → complete Stripe Checkout (test mode) → verify `Subscription` record created → trigger `invoice.payment_failed` via Stripe CLI → verify account gated.
- **Branding**: Run the app and confirm logo, product name, and primary color reflect your brand across the dashboard, widget, and email templates.
- **RAG agent**: Create an agent → upload a PDF → wait for indexing → attach to a test inbox → send a question from the widget → verify the answer cites the PDF content.
- **Tool-calling**: Add an HTTP tool pointing to a public API → chat with the agent → verify it calls the tool and incorporates results.
- **Voice**: Use Twilio test credentials to initiate a call → verify audio flows through the bridge to OpenAI Realtime and back.
- **Metering**: After AI calls, query `AiUsageRecord` and verify Stripe usage events appear in the Stripe dashboard.

---

**Decisions**
- **LiteLLM sidecar** instead of per-provider Ruby adapters — one maintenance point, 100+ providers, handles BYOK per-request, OpenAI-compatible API means no code changes when adding new providers.
- **Wisper listeners** for agent routing — follows existing Chatwoot patterns exactly; no core file modifications needed.
- **`saas/` module** instead of editing `enterprise/` — keeps your IP in a clean boundary and makes upstream syncing from `chatwoot/chatwoot` safer.
- **`pay` gem** for Stripe — handles webhooks, subscriptions, and payment method management with minimal boilerplate; battle-tested in Rails SaaS projects.
- **pgvector** for embeddings — already in the stack; avoids adding Pinecone/Qdrant as another service dependency.
- **OpenAI Realtime API** for voice — native speech-in/speech-out with tool-calling in a single WebSocket; far simpler than STT→LLM→TTS pipelines.