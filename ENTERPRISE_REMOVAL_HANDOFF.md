# Enterprise Edition Removal — Handoff / Restart Guide

Branch: `feat/remove-enterprise-keep-captain-campaigns`
Commits: `0284f7838` (refactor) + `8465b50fb` (spec fixes)

## What was done (already committed)

Goal: delete the `enterprise/` overlay, keep the **AI agent (captain)** and
**WhatsApp marketing campaigns**, and remove the enterprise toggle.

Findings that drove the approach:
- WhatsApp marketing campaigns were **already 100% OSS** (`app/models/campaign.rb`,
  `app/services/whatsapp/oneoff_campaign_service.rb`, routes under
  `inboxes/:id/campaigns`). No work needed there.
- The **AI agent (captain) lived entirely inside `enterprise/`** (controllers,
  models, services, jobs, views, `lib/captain`). Captain routes in
  `config/routes.rb` were already unconditional — they just died without the
  enterprise controllers.

Concrete changes:
1. Moved the whole captain tree out of `enterprise/` into `app/` and `lib/`
   (git recorded as renames, history preserved). 14 controllers, 9 models,
   68 services, plus jobs/builders/finders/helpers/listeners/policies/validators/views.
2. Dropped the 3 `Enterprise::Captain` quota/billing wrappers
   (`lib/enterprise/captain/*`) — they only metered cloud/self-hosted-ee usage.
3. Folded `Enterprise::Account#captain_document_sync_interval(s)` into the
   `AccountCaptainAutoResolve` concern so document auto-sync keeps working.
4. Fixed captain prompt paths after the move (`lib/captain/prompts/...`).
5. `config/application.rb`: removed the enterprise loader/eager-load/view-path
   initializer blocks. Kept `prepend_mod_with` (now a harmless no-op since
   `ChatwootApp.extensions` is empty).
6. `config/routes.rb`: removed all `ChatwootApp.enterprise?` guards and the
   `namespace :enterprise` block. Captain routes were already unconditional.
7. Removed the dead `config/initializers/audited.rb` (pointed at the deleted
   `Enterprise::AuditLog`).
8. Frontend: deleted `api/enterprise/`, `settings/billing`, `settings/upgrade`
   (route + pages), removed the UpgradePage from `Dashboard.vue`, gated the
   billing sidebar link behind cloud only, decoupled `useCaptain.fetchLimits`
   (no-op) and `captain/Index.vue` feature visibility from `isEnterprise`.
9. Deleted `enterprise/` and `spec/enterprise/`.

## What was verified here (this session)

- **Ruby syntax**: all 149 changed `.rb`/`.rake` files pass `ruby -c` (via
  docker `ruby:3.4-slim`).
- **Frontend lint**: `eslint` clean on every edited JS/Vue file.
- **JS tests** (`npx vitest run`): 47 captain/Dashboard/useCaptain/useConfig
  specs pass. `Dashboard.spec.js` and `useCaptain.spec.js` were rewritten to
  match the new (no upgrade page, no limits endpoint) behavior.
- **Self-audit**: zero `Enterprise::` code references remain; zero stale
  `enterprise/lib`/`enterprise/app` paths. `git ls-files enterprise` is empty.

## What you MUST verify in your environment (could NOT be done here)

This sandbox has no Ruby/Rails/Postgres and could not boot the app. The real
gate is a full boot + migration + smoke test:

1. **Bundle + boot**
   - `bundle install` (or let docker build do it)
   - `bundle exec rails db:migrate` (captain tables already exist in OSS
     migrations — no new migration needed for this change)
   - Boot via your docker compose: `docker compose up -d --build`
2. **Health check** the web/rails container; watch logs for boot/runtime errors
   (especially anything referencing a deleted class during autoload).
3. **Smoke test the two kept features**:
   - AI agent: `GET /api/v1/accounts/:id/captain/assistants` (needs
     `CAPTAIN_OPEN_AI_API_KEY` and `captain_integration` feature flag on).
   - WhatsApp campaign: `GET /api/v1/accounts/:id/inboxes/:id/campaigns`.
4. **Run the Ruby test suite** (not done here): `bundle exec rspec` — confirm
   no OSS spec breaks on a deleted `Enterprise::*` reference at load time.
5. **Frontend build**: `pnpm build` to confirm the dashboard bundles cleanly
   (eslint passed; full production build not run here).

## Known intentional behavior changes (by design)

- `ChatwootApp.enterprise?` is now always false → SLA, voice calls, audit
  dashboards, agent capacity, custom roles, etc. are inactive (turned off).
- Captain usage-limit banners (document/response quota) never show because the
  `/accounts/:id/limits` endpoint is gone. If you want hard caps for
  self-hosted later, that's a separate feature.
- `message_reports` controller still 404s unless `chatwoot_cloud?` (cloud-only
  feature); route left in place.

## If something breaks at boot

- Search the backtrace for a deleted `Enterprise::` or `enterprise/` symbol.
  The two most likely culprits were already fixed (`audited.rb` initializer,
  `Account::PlanUsageAndLimits` prepend is now a no-op).
- Any `prepend_mod_with('X')` / `include_mod_with('X')` referencing an
  enterprise module is safe to leave — it's a no-op when extensions is empty.
