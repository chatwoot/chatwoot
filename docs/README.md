# AirysChat Documentation

> Multi-tenant AI agent SaaS built on Chatwoot

## Docs

| Document | Description |
|----------|-------------|
| [Fork Plan & Progress](fork-plan.md) | Phase-by-phase implementation plan with progress tracker |
| [Architecture](architecture.md) | System architecture, tech stack, SaaS module pattern, directory structure |
| [Billing](billing.md) | Stripe integration, plans, subscriptions, webhooks, API endpoints |
| [Branding](branding.md) | Colors, logos, product name, locale customization |
| [Upstream Sync](upstream-sync.md) | How to pull security patches from upstream Chatwoot |

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
# Edit .env with your Stripe keys, etc.

# Run
overmind start -f Procfile.dev
```

## Key Concepts

- **SaaS module** (`saas/`) — All custom code lives here, extending Chatwoot core via module prepending
- **No enterprise/** — Removed; replaced by `saas/` with the same extension mechanism
- **Upstream safe** — Automated weekly sync from `chatwoot/chatwoot` via GitHub Actions PR
