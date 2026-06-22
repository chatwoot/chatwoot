# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See [AGENTS.md](./AGENTS.md) for build commands, code style, styling rules, commit conventions, and project-specific guidelines. The rules there apply equally here.

## Architecture Overview

Chatwoot is an omnichannel customer support platform. The primary stack is **Rails 7** (API + server-rendered auth/admin pages) with a **Vue 3** SPA frontend, **Sidekiq** for background jobs, **Action Cable** (WebSockets) for real-time updates, and **Redis** for caching and pub/sub.

### Backend structure

All customer-facing APIs live under `app/controllers/api/v1/accounts/` and are scoped by `account_id`. The key domain models are:

- **Account** — top-level tenant; nearly every model has `account_id`
- **Inbox** — a communication channel instance (email inbox, WhatsApp number, web widget, etc.). It owns a polymorphic `channel` (`Channel::WebWidget`, `Channel::Email`, `Channel::FacebookPage`, etc. in `app/models/channel/`)
- **Conversation** — a thread between a contact and agents, always tied to an inbox
- **Message** — individual messages within a conversation
- **Contact** / **ContactInbox** — a customer and their identity within a specific inbox

Business logic lives in `app/services/` (organized by domain). Heavy lifting that must not block the request goes through `app/jobs/`. Reusable pieces used across jobs/services that are not Rails-conventional live in `lib/`.

**Event system**: Model callbacks and controller actions call `Dispatcher.dispatch(event_name, ...)`. `app/listeners/` subscribe to these events (sync or async) and fan out to jobs, webhooks, Action Cable broadcasts, and notifications.

### Frontend structure

The frontend is built with Vite (`vite-plugin-ruby`) and has multiple independent entrypoints in `app/javascript/entrypoints/`:

| Entrypoint | Path | Purpose |
|---|---|---|
| `dashboard.js` | `app/javascript/dashboard/` | Main agent workspace (the core app) |
| `v3app.js` | `app/javascript/v3/` | Auth / onboarding flows |
| `widget.js` | `app/javascript/widget/` | Embeddable customer chat widget |
| `portal.js` | `app/javascript/portal/` | Customer-facing help center |
| `survey.js` | `app/javascript/survey/` | CSAT survey page |
| `superadmin.js` | `app/javascript/superadmin_pages/` | Super-admin UI |

`app/javascript/shared/` contains utilities, composables, and components used across all entrypoints.

**Import aliases** (defined in `vite.shared.ts`):
- `dashboard` → `app/javascript/dashboard`
- `next` → `app/javascript/dashboard/components-next`
- `shared` → `app/javascript/shared`
- `v3` → `app/javascript/v3`
- `widget` → `app/javascript/widget`

### Frontend state management

The dashboard uses **Vuex** (`dashboard/store/`) for most global state. A migration to **Pinia** (`dashboard/stores/`) is in progress — new features should prefer Pinia. The Captain AI stores are already on Pinia.

### Component system

`dashboard/components-next/` is the active design system used for all new UI work (message bubbles, sidebar, dialogs, etc.). `dashboard/components/` is legacy and being deprecated — do not add new components there.

### Captain (AI features)

Captain is Chatwoot's AI layer. OSS tooling lives in `lib/captain/` and `app/services/captain/`; enterprise-specific services (LLM connectors, copilot, voice) live under `enterprise/`. Config for LLM providers is in `config/llm.yml` and `config/llm_models.json`.

### Enterprise Edition

`enterprise/` mirrors the OSS directory layout and extends it via Ruby's `prepend_mod_with` / `include_mod_with` hooks. When modifying OSS code that has enterprise equivalents, always check and update `enterprise/` in the same change. Enterprise-only models, controllers, and services live exclusively under `enterprise/app/`.
