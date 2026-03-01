# AirysChat Architecture

## Overview

AirysChat is a multi-tenant AI agent SaaS built as a fork of [Chatwoot](https://github.com/chatwoot/chatwoot). It replaces the proprietary `enterprise/` module with a custom `saas/` module, preserving the ability to merge upstream security patches.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Ruby on Rails 7.1 (Ruby 3.4.4) |
| Frontend | Vue 3 (Composition API) + Tailwind CSS |
| Database | PostgreSQL 16 with pgvector extension |
| Cache / Queues | Redis + Sidekiq |
| Auth | Devise (authentication) + Pundit (authorization) |
| Admin | Administrate (Super Admin dashboards) |
| Billing | Stripe gem (~>18.0) |
| LLM Proxy | LiteLLM sidecar (planned — Phase 3) |
| Embeddings | pgvector via `neighbor` gem |
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
│   ├── services/
│   ├── javascript/dashboard/     # Vue 3 frontend
│   └── ...
├── saas/                         # AirysChat custom code
│   ├── app/
│   │   ├── controllers/
│   │   │   └── saas/
│   │   │       ├── api/v1/accounts_controller.rb
│   │   │       └── webhooks/stripe_controller.rb
│   │   ├── jobs/
│   │   ├── listeners/
│   │   ├── models/
│   │   │   └── saas/
│   │   │       ├── account.rb
│   │   │       ├── account/plan_usage_and_limits.rb
│   │   │       ├── ai_usage_record.rb
│   │   │       ├── concerns/account.rb
│   │   │       ├── plan.rb
│   │   │       └── subscription.rb
│   │   ├── policies/
│   │   ├── serializers/
│   │   ├── services/
│   │   │   ├── agent/               # (Phase 4)
│   │   │   ├── llm/                 # (Phase 3)
│   │   │   ├── rag/                 # (Phase 4)
│   │   │   ├── saas/stripe_service.rb
│   │   │   └── voice/               # (Phase 4)
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

## Database

### Core tables (Chatwoot)

- `accounts`, `users`, `conversations`, `messages`, `inboxes`, `contacts`, `teams`, etc.

### SaaS tables (AirysChat additions)

- `saas_plans` — billing plans with limits
- `saas_subscriptions` — per-account Stripe subscription state
- `saas_ai_usage_records` — daily AI token usage tracking

### Planned tables (Phase 4)

- `ai_agents` — agent definitions with LLM config
- `ai_agent_inboxes` — agent ↔ inbox assignments
- `knowledge_bases` — document collections
- `knowledge_documents` — chunked documents with pgvector embeddings
- `agent_tools` — HTTP tool definitions

## Key Patterns

### Wisper Event System

Chatwoot uses Wisper for pub/sub event handling. AI agents will hook into this:

```ruby
# saas/app/listeners/ai_agent_listener.rb
class AiAgentListener < BaseListener
  def conversation_created(event)
    # Check if inbox has AI agent → enqueue reply job
  end

  def message_created(event)
    # Handle incoming messages for AI-powered conversations
  end
end
```

### Background Jobs

All heavy processing runs via Sidekiq:
- Document embedding
- AI agent reply generation
- Stripe webhook processing
- Usage record aggregation

### Feature Gating

Plan limits are enforced via `Saas::Account::PlanUsageAndLimits`, which overrides the core `usage_limits` method to check the account's current plan.
