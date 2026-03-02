# AirysChat Documentation

> Multi-tenant AI agent SaaS built on Chatwoot

## Docs

| Document | Description |
|----------|-------------|
| [Fork Plan & Progress](fork-plan.md) | Phase-by-phase implementation plan with progress tracker |
| [Architecture](architecture.md) | System architecture, tech stack, SaaS module pattern, directory structure |
| [Billing](billing.md) | Stripe integration, plans, subscriptions, webhooks, API endpoints |
| [Branding](branding.md) | Colors, logos, product name, locale customization |
| [Dev Setup](devSetup.md) | Local development setup, prerequisites, environment variables |
| [Upstream Sync](upstream-sync.md) | How to pull security patches from upstream Chatwoot |

## Status

| Phase | Status |
|-------|--------|
| Phase 0–2: Fork, Branding, Billing | ✅ Complete |
| Phase 3: LLM Provider Abstraction | ✅ Complete |
| Phase 4: AI Agent Engine (RAG + Tools + Voice) | ✅ Complete |
| Voice Provider Audit & Best Practices Review | ✅ Complete |
| Phase 5: Agent Builder UI | ⬜ Not Started |
| Phase 6: Docker Deployment | ⬜ Not Started |

## Quick Start

```bash
# Clone
git clone git@github.com:gabrieldeholanda/AirysChat.git
cd AirysChat

# Install dependencies
bundle install && pnpm install

# Setup database
bundle exec rails db:create db:migrate

# Seed billing plans
bundle exec rake saas:seed_plans

# Configure env
cp .env.example .env
# Edit .env with your Stripe keys, LLM provider keys, etc.

# Start LiteLLM sidecar (for AI features)
docker compose up -d litellm

# Run
overmind start -f Procfile.dev
```

## Key Concepts

- **SaaS module** (`saas/`) — All custom code lives here, extending Chatwoot core via module prepending
- **No enterprise/** — Removed; replaced by `saas/` with the same extension mechanism
- **Upstream safe** — Automated weekly sync from `chatwoot/chatwoot` via GitHub Actions PR
- **LiteLLM sidecar** — OpenAI-compatible proxy supporting 100+ LLM providers with BYOK
- **AI Agent Engine** — RAG + tool-calling + voice agents with conversation routing via Wisper events
- **Voice providers** — Provider-agnostic architecture (OpenAI Realtime GA + ElevenLabs) with Twilio bridge
- **Stripe billing** — Hybrid base plan + metered AI usage with async webhook processing
