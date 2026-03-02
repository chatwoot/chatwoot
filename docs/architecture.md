# AirysChat Architecture

## Overview

AirysChat is a multi-tenant AI agent SaaS built as a fork of [Chatwoot](https://github.com/chatwoot/chatwoot). It replaces the proprietary `enterprise/` module with a custom `saas/` module, preserving the ability to merge upstream security patches.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 7.1 (Ruby 3.4.4) |
| Frontend | Vue 3 (Composition API) + Tailwind CSS |
| Database | PostgreSQL 17 with pgvector 0.8.2 |
| Cache / Queues | Redis + Sidekiq |
| Auth | Devise (authentication) + Pundit (authorization) |
| Admin | Administrate (Super Admin dashboards) |
| Billing | Stripe gem (~>18.0) |
| LLM Proxy | LiteLLM Docker sidecar (port 4000) |
| Embeddings | pgvector via `neighbor` gem (cosine similarity) |
| Voice / Realtime | OpenAI Realtime API (GA) + ElevenLabs Conversational AI |
| WebSocket Client | `faye-websocket` gem (EventMachine-based) |
| Telephony | Twilio Voice SDK (`twilio-ruby` v7.6.0) |
| Deployment | Docker Compose |

## SaaS Module Pattern

The key architectural decision is the `saas/` module, which replaces Chatwoot's `enterprise/` directory. This works via Rails' autoload system and Chatwoot's built-in extension mechanism.

### How it works

1. **`lib/chatwoot_app.rb`** defines:
   ```ruby
   def extensions
     ["saas"]
   end

   def saas?
     true
   end

   def enterprise?
     false
   end
   ```

2. **`config/application.rb`** adds `saas/` paths to Rails autoload:
   ```ruby
   config.eager_load_paths << Rails.root.join("saas/app/models")
   config.eager_load_paths << Rails.root.join("saas/app/controllers")
   config.eager_load_paths << Rails.root.join("saas/app/services")
   # ... etc
   ```

3. **`InjectEnterpriseEditionModule`** (a Chatwoot core concern) automatically discovers and prepends `Saas::` namespaced modules. For example:
   - `Account` model gets extended by `Saas::Account` and `Saas::Concerns::Account`
   - `Account::PlanUsageAndLimits` is overridden by `Saas::Account::PlanUsageAndLimits`

4. **Rake tasks** are loaded via `saas/tasks_railtie.rb`, which registers task files from `saas/lib/tasks/`.

### Why this pattern?

- **Clean separation** — All custom code lives under `saas/`, making upstream merges safer
- **No core modifications** — Extension modules override behavior via `prepend`, not by editing core files
- **Familiar pattern** — Mirrors exactly how Chatwoot's own `enterprise/` module works

## Directory Structure

```
AirysChat/
├── app/                          # Chatwoot core (upstream)
│   ├── controllers/
│   ├── models/
│   ├── channels/
│   │   └── llm_channel.rb        # ActionCable for LLM streaming
│   ├── services/
│   ├── javascript/dashboard/     # Vue 3 frontend
│   └── ...
├── saas/                         # AirysChat custom code
│   ├── app/
│   │   ├── controllers/
│   │   │   └── saas/
│   │   │       ├── api/v1/
│   │   │       │   ├── accounts_controller.rb
│   │   │       │   ├── ai_agents_controller.rb
│   │   │       │   ├── ai_agent_inboxes_controller.rb
│   │   │       │   ├── agent_tools_controller.rb
│   │   │       │   ├── knowledge_bases_controller.rb
│   │   │       │   ├── knowledge_documents_controller.rb
│   │   │       │   ├── llm_controller.rb
│   │   │       │   └── voice/twilio_controller.rb
│   │   │       └── webhooks/stripe_controller.rb
│   │   ├── dispatchers/
│   │   │   └── saas/async_dispatcher.rb
│   │   ├── jobs/
│   │   │   ├── ai_agent_reply_job.rb
│   │   │   ├── saas/stripe_webhook_job.rb
│   │   │   └── rag/document_ingestion_job.rb
│   │   ├── listeners/
│   │   │   └── ai_agent_listener.rb
│   │   ├── models/
│   │   │   ├── channel/voice.rb
│   │   │   └── saas/
│   │   │       ├── account.rb
│   │   │       ├── account/plan_usage_and_limits.rb
│   │   │       ├── ai_agent.rb
│   │   │       ├── ai_agent_inbox.rb
│   │   │       ├── ai_usage_record.rb
│   │   │       ├── agent_tool.rb
│   │   │       ├── concerns/account.rb
│   │   │       ├── knowledge_base.rb
│   │   │       ├── knowledge_document.rb
│   │   │       ├── plan.rb
│   │   │       └── subscription.rb
│   │   ├── policies/
│   │   ├── serializers/
│   │   ├── services/
│   │   │   ├── agent/
│   │   │   │   ├── executor.rb
│   │   │   │   └── tool_runner.rb
│   │   │   ├── llm/
│   │   │   │   └── client.rb
│   │   │   ├── rag/
│   │   │   │   ├── embedding_service.rb
│   │   │   │   ├── search_service.rb
│   │   │   │   ├── text_chunker.rb
│   │   │   │   └── url_crawler.rb
│   │   │   ├── saas/stripe_service.rb
│   │   │   └── voice/
│   │   │       ├── fallback_pipeline.rb
│   │   │       ├── provider/
│   │   │       │   ├── base.rb
│   │   │       │   ├── elevenlabs.rb
│   │   │       │   └── openai.rb
│   │   │       ├── realtime_session.rb
│   │   │       └── twilio_bridge.rb
│   │   └── views/
│   ├── config/initializers/
│   ├── lib/tasks/saas_plans.rake
│   ├── spec/
│   └── tasks_railtie.rb
├── config/
│   ├── application.rb            # Modified: saas/ autoload paths
│   ├── routes.rb                 # Modified: saas routes
│   └── installation_config.yml   # Modified: AirysChat branding
├── lib/
│   └── chatwoot_app.rb           # Modified: extensions = ["saas"]
├── docs/                         # Documentation
│   ├── README.md
│   ├── fork-plan.md
│   ├── architecture.md
│   ├── billing.md
│   ├── branding.md
│   └── upstream-sync.md
└── .github/workflows/
    └── upstream-sync.yml         # Weekly upstream sync
```

## Extension Points

### Models

To extend an existing Chatwoot model, create a module under `saas/app/models/saas/`:

```ruby
# saas/app/models/saas/account.rb
module Saas::Account
  extend ActiveSupport::Concern

  included do
    has_one :saas_subscription, class_name: 'Saas::Subscription', dependent: :destroy
  end

  def current_plan
    saas_subscription&.plan
  end
end
```

The `InjectEnterpriseEditionModule` concern on `Account` will automatically prepend `Saas::Account`.

### Controllers

SaaS-specific controllers live under `saas/app/controllers/saas/` and are mounted via explicit route definitions in `config/routes.rb`:

```ruby
if ChatwootApp.saas?
  namespace :saas do
    # ...routes...
  end
end
```

### Frontend

Frontend additions use the existing Vue 3 architecture:
- API clients: `app/javascript/dashboard/api/saas/`
- Store modules: extend existing Vuex stores
- Routes: add to existing route definitions
- Components: use Composition API with `<script setup>`

### Agent Builder UI (Phase 5)

The Agent Builder is a full Vue 3 SPA section under `/ai-agents`:

```
app/javascript/dashboard/
├── api/saas/aiAgents.js                    # API client (extends ApiClient)
├── store/modules/aiAgents.js               # Vuex store module
├── i18n/locale/en/aiAgents.json            # i18n translations
└── routes/dashboard/aiAgents/
    ├── AiAgentsRouteView.vue               # Router-view wrapper
    ├── aiAgents.routes.js                  # Route definitions
    ├── pages/
    │   ├── AgentListPage.vue               # Grid of agent cards
    │   └── AgentDetailPage.vue             # Tabbed detail view
    └── components/
        ├── AgentCard.vue                   # Card with type/status/counts
        ├── CreateAgentDialog.vue           # Create/edit modal
        ├── DeleteAgentDialog.vue           # Delete confirmation
        └── tabs/
            ├── SetupTab.vue                # Name, type, model, prompt, temperature
            ├── KnowledgeTab.vue            # KB + document CRUD
            ├── ToolsTab.vue                # HTTP tool builder
            ├── VoiceTab.vue                # Voice provider config
            └── DeployTab.vue               # Inbox connections
```

Routes are lazy-loaded and restricted to `administrator` permission. The sidebar entry appears after the Captain section.

## Database

### Core tables (Chatwoot)

- `accounts`, `users`, `conversations`, `messages`, `inboxes`, `contacts`, `teams`, etc.

### SaaS tables (AirysChat additions)

- `saas_plans` — billing plans with limits
- `saas_subscriptions` — per-account Stripe subscription state
- `saas_ai_usage_records` — daily AI token usage tracking

### AI Agent tables (Phase 4)

- `ai_agents` — agent definitions with type enum (rag/tool_calling/voice/hybrid), LLM config (JSONB), system prompt
- `ai_agent_inboxes` — agent ↔ inbox assignments (join table)
- `knowledge_bases` — document collections per AI agent
- `knowledge_documents` — chunked documents with `embedding vector(1536)` via pgvector (ivfflat index)
- `agent_tools` — HTTP tool definitions with Liquid template config
- `channel_voices` — voice channel with phone_number, provider, provider_config (JSONB)

## Key Patterns

### Wisper Event System

Chatwoot uses Wisper for pub/sub event handling. AI agents hook into this via `AiAgentListener`:

```ruby
# saas/app/listeners/ai_agent_listener.rb
class AiAgentListener < BaseListener
  def message_created(event)
    # Check if inbox has active AI agent → enqueue AiAgentReplyJob
    conversation = event.data[:conversation]
    agent = Saas::AiAgentInbox.active_agent_for(conversation.inbox)
    AiAgentReplyJob.perform_later(conversation.id, message.id) if agent
  end
end
```

Registered in `Saas::AsyncDispatcher` via `prepend_mod_with` to add `AiAgentListener` to the dispatcher's listener list.

### Background Jobs

All heavy processing runs via Sidekiq:
- `AiAgentReplyJob` — AI agent reply generation (builds conversation history, runs `Agent::Executor`, posts reply)
- `LlmStreamJob` — streaming LLM completions via ActionCable with token metering
- `Rag::DocumentIngestionJob` — text chunking → embedding → pgvector storage
- `Saas::StripeWebhookJob` — async Stripe webhook processing with idempotency
- Usage record aggregation

### Feature Gating

Plan limits are enforced via `Saas::Account::PlanUsageAndLimits`, which overrides the core `usage_limits` method to check the account's current plan.

## LLM Subsystem

### LiteLLM Sidecar

LiteLLM runs as a Docker sidecar (port 4000), providing an OpenAI-compatible `/v1/chat/completions` endpoint that proxies to 100+ providers. Configuration: `config/litellm.yml` (14+ model definitions).

### Llm::Client

Thin `Net::HTTP` wrapper (`saas/app/services/llm/client.rb`) with:
- Blocking `chat()` and streaming `chat_stream()` (SSE parsing)
- `embed()` for vector embeddings
- `healthy?` / `models()` for proxy introspection
- BYOK support via per-request `api_key` parameter
- Custom error hierarchy: `RequestError`, `RateLimitError`, `AuthenticationError`, `TimeoutError`

### LLM Streaming Flow

```
Client → POST /saas/api/v1/accounts/:id/llm/completions (stream: true)
  → LlmStreamJob (Sidekiq)
    → Llm::Client#chat_stream (SSE from LiteLLM)
    → LlmChannel.broadcast_chunk (ActionCable, per-account stream)
    → Saas::AiUsageRecord.record_usage! (token metering)
```

### Config files

- `config/llm.yml` — provider definitions, model lists, feature defaults, credit multipliers
- `config/litellm.yml` — LiteLLM proxy model routing config

## RAG Pipeline

```
Document/URL → Rag::DocumentIngestionJob
  → Rag::UrlCrawler (Firecrawl API or Nokogiri fallback)
  → Rag::TextChunker (recursive character splitter, 1000 chars, 200 overlap)
  → Rag::EmbeddingService (batched via Llm::Client#embed)
  → KnowledgeDocument records with vector(1536) embeddings
```

At query time:
```
User message → Rag::SearchService.search(query, knowledge_bases)
  → pgvector cosine similarity (nearest_neighbors via `neighbor` gem)
  → Top-5 chunks → Rag::SearchService.build_context
  → Injected into system prompt before LLM call
```

## Agent Engine

### Agent::Executor

Multi-turn orchestrator (`saas/app/services/agent/executor.rb`):
1. Assembles system prompt + RAG context
2. Calls LLM with conversation history + available tools
3. If LLM returns tool calls → `Agent::ToolRunner` executes them
4. Loops (max 5 iterations) until LLM produces final text response
5. Tracks token usage via `Saas::AiUsageRecord`

### Agent::ToolRunner

Executes tools defined as `Saas::AgentTool` records:
- **HTTP tools** — Liquid template interpolation for URL, headers, body → HTTP request → JSON response
- **Built-in tools** — `handoff_to_human` (unassigns agent, creates activity message)
- Tool definitions exported to OpenAI function-calling format via `AgentTool#to_llm_tool`

## Voice Architecture

### Provider Abstraction

```
Voice::Provider.for(ai_agent:) → factory method
  ├── Voice::Provider::Openai    — OpenAI Realtime API (GA format)
  ├── Voice::Provider::Elevenlabs — ElevenLabs Conversational AI
  └── (extensible for future providers)
```

All providers implement the `Voice::Provider::Base` interface:
- `connect!` / `disconnect!` — WebSocket lifecycle
- `send_audio(payload)` — stream audio frames
- `synthesize(text)` — TTS
- `transcribe(audio)` — STT
- Callbacks: `on_audio`, `on_transcript`, `on_error`

### Twilio Integration Flow

```
Incoming call → Twilio → POST /saas/api/v1/voice/twilio/incoming
  → TwiML response with <Stream> WebSocket URL
  → Twilio connects WebSocket → VoiceRealtimeChannel (ActionCable)
  → Voice::TwilioBridge bridges audio ↔ Voice::Provider
  → Provider processes audio, returns audio/transcript
  → TwilioBridge transmits audio back to Twilio → caller hears response
```

### OpenAI Realtime Provider (GA)

Uses GA API format with nested `audio {}` config:
- Native g711_ulaw format (no transcoding for Twilio)
- Configurable VAD: `server_vad` or `semantic_vad`
- Noise reduction: `far_field` for phone calls
- Tool-calling support (same tools as text agent)
- Dual event name handling (beta + GA compatibility)

### Fallback Pipeline

When realtime streaming isn't available:
```
Audio → Voice::Provider.transcribe (STT)
  → Agent::Executor (text-based reasoning)
  → Voice::Provider.synthesize (TTS)
  → Audio response
```
