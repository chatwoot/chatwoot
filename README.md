<img src="./.github/screenshots/header.png#gh-light-mode-only" width="100%" alt="Header light mode"/>
<img src="./.github/screenshots/header-dark.png#gh-dark-mode-only" width="100%" alt="Header dark mode"/>

___

# WeaveSmart Chat (WSC) — Fork Overview

This repository is a productised fork of Chatwoot tailored for UK/EU SMEs. It preserves Chatwoot core while adding an extension layer under the Rails engine `Weave::Core` (mounted at `/wsc`). All new endpoints live under this namespace and are documented via OpenAPI with a TypeScript SDK consumed by the web app.

Stack & Standards (WSC)
- Backend: Ruby on Rails (Chatwoot base) + engine `Weave::Core`.
- Frontend: Vue 3 with Vuetify (dashboard/admin) and Anime.js for micro‑animations. Default locale: English (UK).
- Data stores: PostgreSQL; Redis for cache/queues/WebSocket.
- CI/CD: GitHub Actions. `develop` → staging; `main` → production. Release tags `vX.Y.Z` with automated changelog.
- Contracts: OpenAPI for WSC endpoints; TS SDK auto‑generated.
  - SDK generation runs on `pnpm install` and in CI; see `pnpm sdk:wsc`.
- Security/Ops: 2FA (owner/admin), CSP + SRI, per‑tenant/channel/module rate limits, structured JSON logs with `tenantId` and `traceId`, health checks, Sentry, Prometheus, daily backups with weekly restore test.
- Design system: Primary `#8127E8`, accent `#FF6600`; brand fonts; light/dark themes.
- Performance budgets: Widget ≤ 100KB gz; dashboard route bundle ≤ 200KB gz; API p95 ≤ 300ms (read) / ≤ 600ms (write) on staging data.

Feature Flags & Plans (scaffold)
- Plans: basic, pro, premium, app, custom. Plans are stored in `weave_core_account_plans` (engine).
- Feature toggles: per‑account overrides in `weave_core_feature_toggles`; defaults derived from the plan.
- API: `GET/PATCH /wsc/api/accounts/:account_id/features` (Chatwoot auth; admin required for PATCH).
- OpenAPI: `swagger/wsc/openapi.yaml`; generate TS SDK via `pnpm sdk:wsc` into `app/javascript/sdk/wsc/`.
 - Migrations: engine migrations auto‑append; run `bundle exec rails db:migrate`.
 - Admin UI (minimal): visit `/app/accounts/:accountId/settings/weave` to view/update feature toggles.

Rate Limiting (per tenant/channel/module)
- Implemented via Rack::Attack in the engine (no core edits):
  - Per‑account RPM for all account‑scoped APIs.
  - Messaging writes (conversations/messages) per account.
  - WhatsApp inbound webhooks per account (scoped via phone → channel → account).
  - Widget writes per account (scoped via `website_token`).
- Limits are plan‑based defaults (Basic/Pro/Premium/App/Custom) and can be tuned in code.
- 429 responses may be returned when thresholds are exceeded.

Structured JSON Logs
- Enabled via Lograge JSON (`LOGRAGE_ENABLED=true`).
- Payload includes `tenantId` (when available) and `traceId` (request id) for correlation.
- Sidekiq logs remain JSON-formatted; future work may add correlation fields to jobs.

2FA (owner/admin)
- Engine adds user 2FA fields and endpoints:
  - `GET /wsc/api/profile/two_factor/setup` → returns secret + otpauth URL.
  - `POST /wsc/api/profile/two_factor/enable` with `{ code }` → enables and returns backup codes.
  - `POST /wsc/api/profile/two_factor/disable` with `{ code | backup_code }`.
- Enforcement (admins): set `WSC_2FA_ENFORCE=true` to require 2FA for administrator requests to account‑scoped APIs. Non‑account routes are not enforced.

UK Formatting
- Default locale `en‑GB` in dashboard and widget. Helpers in `app/javascript/weave/format.ts`:
  - `formatDateTimeUK(date)` (DD/MM/YYYY, 24h)
  - `formatDateUK(date)`
  - `formatCurrencyGBP(amount)` (GBP £)

Contributions must use UK English, DD/MM/YYYY, 24h time, and GBP (£).

# Chatwoot

The modern customer support platform, an open-source alternative to Intercom, Zendesk, Salesforce Service Cloud etc.

<p>
  <a href="https://codeclimate.com/github/chatwoot/chatwoot/maintainability"><img src="https://api.codeclimate.com/v1/badges/e6e3f66332c91e5a4c0c/maintainability" alt="Maintainability"></a>
  <img src="https://img.shields.io/circleci/build/github/chatwoot/chatwoot" alt="CircleCI Badge">
    <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/pulls/chatwoot/chatwoot" alt="Docker Pull Badge"></a>
  <a href="https://hub.docker.com/r/chatwoot/chatwoot/"><img src="https://img.shields.io/docker/cloud/build/chatwoot/chatwoot" alt="Docker Build Badge"></a>
  <img src="https://img.shields.io/github/commit-activity/m/chatwoot/chatwoot" alt="Commits-per-month">
  <a title="Crowdin" target="_self" href="https://chatwoot.crowdin.com/chatwoot"><img src="https://badges.crowdin.net/e/37ced7eba411064bd792feb3b7a28b16/localized.svg"></a>
  <a href="https://discord.gg/cJXdrwS"><img src="https://img.shields.io/discord/647412545203994635" alt="Discord"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fuptime.json" alt="uptime"></a>
  <a href="https://status.chatwoot.com"><img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fchatwoot%2Fstatus%2Fmaster%2Fapi%2Fchatwoot%2Fresponse-time.json" alt="response time"></a>
  <a href="https://artifacthub.io/packages/helm/chatwoot/chatwoot"><img src="https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/artifact-hub" alt="Artifact HUB"></a>
</p>


<p>
  <a href="https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master" alt="Deploy to Heroku">
     <img width="150" alt="Deploy" src="https://www.herokucdn.com/deploy/button.svg"/>
  </a>
  <a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
     <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
  </a>
</p>

<img src="./.github/screenshots/dashboard.png#gh-light-mode-only" width="100%" alt="Chat dashboard dark mode"/>
<img src="./.github/screenshots/dashboard-dark.png#gh-dark-mode-only" width="100%" alt="Chat dashboard"/>

---

Chatwoot is the modern, open-source, and self-hosted customer support platform designed to help businesses deliver exceptional customer support experience. Built for scale and flexibility, Chatwoot gives you full control over your customer data while providing powerful tools to manage conversations across channels.

### ✨ Captain – AI Agent for Support

Supercharge your support with Captain, Chatwoot’s AI agent. Captain helps automate responses, handle common queries, and reduce agent workload—ensuring customers get instant, accurate answers. With Captain, your team can focus on complex conversations while routine questions are resolved automatically. Read more about Captain [here](https://chwt.app/captain-docs).

### 💬 Omnichannel Support Desk

Chatwoot centralizes all customer conversations into one powerful inbox, no matter where your customers reach out from. It supports live chat on your website, email, Facebook, Instagram, Twitter, WhatsApp, Telegram, Line, SMS etc.

### 📚 Help center portal

Publish help articles, FAQs, and guides through the built-in Help Center Portal. Enable customers to find answers on their own, reduce repetitive queries, and keep your support team focused on more complex issues.

### 🗂️ Other features

#### Collaboration & Productivity

- Private Notes and @mentions for internal team discussions.
- Labels to organize and categorize conversations.
- Keyboard Shortcuts and a Command Bar for quick navigation.
- Canned Responses to reply faster to frequently asked questions.
- Auto-Assignment to route conversations based on agent availability.
- Multi-lingual Support to serve customers in multiple languages.
- Custom Views and Filters for better inbox organization.
- Business Hours and Auto-Responders to manage response expectations.
- Teams and Automation tools for scaling support workflows.
- Agent Capacity Management to balance workload across the team.

#### Customer Data & Segmentation
- Contact Management with profiles and interaction history.
- Contact Segments and Notes for targeted communication.
- Campaigns to proactively engage customers.
- Custom Attributes for storing additional customer data.
- Pre-Chat Forms to collect user information before starting conversations.

#### Integrations
- Slack Integration to manage conversations directly from Slack.
- Dialogflow Integration for chatbot automation.
- Dashboard Apps to embed internal tools within Chatwoot.
- Shopify Integration to view and manage customer orders right within Chatwoot.
- Use Google Translate to translate messages from your customers in realtime.
- Create and manage Linear tickets within Chatwoot.

#### Reports & Insights
- Live View of ongoing conversations for real-time monitoring.
- Conversation, Agent, Inbox, Label, and Team Reports for operational visibility.
- CSAT Reports to measure customer satisfaction.
- Downloadable Reports for offline analysis and reporting.


## Documentation

Detailed documentation is available at [chatwoot.com/help-center](https://www.chatwoot.com/help-center).

## Translation process

The translation process for Chatwoot web and mobile app is managed at [https://translate.chatwoot.com](https://translate.chatwoot.com) using Crowdin. Please read the [translation guide](https://www.chatwoot.com/docs/contributing/translating-chatwoot-to-your-language) for contributing to Chatwoot.

## Branching model

We use the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/) branching model. The base branch is `develop`.
If you are looking for a stable version, please use the `master` or tags labelled as `v1.x.x`.

## Deployment

### Heroku one-click deploy

Deploying Chatwoot to Heroku is a breeze. It's as simple as clicking this button:

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/chatwoot/chatwoot/tree/master)

Follow this [link](https://www.chatwoot.com/docs/environment-variables) to understand setting the correct environment variables for the app to work with all the features. There might be breakages if you do not set the relevant environment variables.


### DigitalOcean 1-Click Kubernetes deployment

Chatwoot now supports 1-Click deployment to DigitalOcean as a kubernetes app.

<a href="https://marketplace.digitalocean.com/apps/chatwoot?refcode=f2238426a2a8" alt="Deploy to DigitalOcean">
  <img width="200" alt="Deploy to DO" src="https://www.deploytodo.com/do-btn-blue.svg"/>
</a>

### Other deployment options

For other supported options, checkout our [deployment page](https://chatwoot.com/deploy).

## Security

Looking to report a vulnerability? Please refer our [SECURITY.md](./SECURITY.md) file.

## Community

If you need help or just want to hang out, come, say hi on our [Discord](https://discord.gg/cJXdrwS) server.

## Contributors

Thanks goes to all these [wonderful people](https://www.chatwoot.com/docs/contributors):

<a href="https://github.com/chatwoot/chatwoot/graphs/contributors"><img src="https://opencollective.com/chatwoot/contributors.svg?width=890&button=false" /></a>


*Chatwoot* &copy; 2017-2025, Chatwoot Inc - Released under the MIT License.
CI/CD & Ops
- Deploys: GitHub Actions deploy to Railway
  - Staging on `develop` via `.github/workflows/deploy_staging.yml` (requires secrets: `RAILWAY_TOKEN`, `RAILWAY_SERVICE_ID_STAGING`, `RAILWAY_ENV_ID_STAGING`).
  - Production on `main` via `.github/workflows/deploy_prod.yml` (requires prod equivalents).
- Releases: Automated via Release Please (`.github/workflows/release_please.yml`), generating tags `vX.Y.Z` and CHANGELOG.
- Backups: Daily `pg_dump` (`.github/workflows/db_backup.yml`) and weekly restore test (`.github/workflows/db_restore_test.yml`). Configure `DATABASE_URL` secret.
- Observability: `/wsc/metrics` exposes Prometheus text format; enable Lograge JSON for structured logs.
- CSP: Baseline CSP is available via engine (`WSC_CSP_ENABLED=true`), report‑only by default.
