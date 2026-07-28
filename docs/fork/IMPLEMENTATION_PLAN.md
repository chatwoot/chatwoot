# Implementation Plan

Phased so every phase leaves the app releasable. All commands run in Docker
(no local Ruby): `docker compose run --rm rails ...` for Ruby,
`docker compose run --rm vite pnpm ...` for JS. Log every error you fix in
`docs/fork/error-log/` before moving on.

## Status (2026-07-03)

**All fork code is shipped — no unimplemented Ruby/JS remains.** Phases 0–4 and
6 are complete; Phases 5 and 7 have only non-code items left (see below).

| Phase | Status |
| --- | --- |
| 0 — Environment sanity | ✅ Done |
| 1 — Inventory | ✅ Done (`INVENTORY.md`) |
| 2 — Overlay bootstrap + entitlement service | ✅ Done |
| 3 — Backend guards | ✅ Done (7 controller + 8 model guards, both concerns, specs) |
| 4 — Provisioning glue | ✅ Done (`PROVISIONING.md`, `CHATWOOT_ENGINE_INTEGRATION.md`) |
| 5 — AI loop verification | ◑ Contract specs done; manual cross-repo run outstanding |
| 6 — UI adaptation | ✅ Done (`useQuota`, banner, at-cap disabling, quota i18n) |
| 7 — Branding pass | ◑ Copy/config/mailers/MFA done; assets + deploy config deferred |

### Remaining work (not code)

1. **Brand assets (Phase 7, Layer 3)** — supply logo / logo-dark / thumbnail /
   favicon / PWA manifest image files, then point the installation configs at
   them. Blocked on brand image files, not on code.
2. **Deploy-time config (Phase 7)** — set `BRAND_URL`, `WIDGET_BRAND_URL`,
   `TERMS_URL`, `PRIVACY_URL`, `MAILER_SENDER_EMAIL`, and the support-contact
   address at deploy. Values only; `BrandingSetup` already consumes them.
3. **Manual AI-loop run (Phase 5)** — exercise incoming → webhook → orchestrator
   stub → API reply end-to-end (exactly one reply, no self-trigger). Requires the
   external orchestrator repo; the Chatwoot-side contract is already spec-covered
   by `spec/custom/contracts/ai_reply_loop_contract_spec.rb`.

## Phase 0 — Environment sanity ✅ Done

> **Superseded by [DEV_SETUP.md](./DEV_SETUP.md)** — use that for the actual
> fresh-clone runbook. Two instructions below turned out to be wrong or stale;
> they are corrected inline and kept for history.

- ~~`docker compose build base rails vite` (first time)~~ — **this fails on a
  fresh clone.** Compose builds targets in parallel, so `rails`/`vite` try to
  resolve the base image before `base` has produced it
  (`pull access denied ... mesh-crm:development`). Build `base` **alone** first,
  then `rails vite`. The combined form only works once the base image already
  exists locally.
- Then `docker compose up -d` — one stack (`mesh-crm`), five services.
- DB is external (Neon Postgres) via `.env` — never commit `.env`, never echo
  its values into docs/logs. **Redis is no longer external**; it is a local
  compose service alongside mailhog (see
  [error-log 2026-07-27](./error-log/2026-07-27-redis-service-missing-from-compose.md)).
- Schema load is **not** automatic — nothing in the boot path migrates. Run
  `db:chatwoot_prepare` with `POSTGRES_STATEMENT_TIMEOUT=600s` (see DEV_SETUP §3).
- Test DB: RSpec needs its own database; confirm `POSTGRES_DATABASE` handling
  for `RAILS_ENV=test` against the external Postgres (or a local throwaway
  Postgres container) before Phase 2. Record whatever you settle on in the
  error log if it required fixing.
- Smoke: `docker compose run --rm rails bundle exec rails runner "puts Account.count"`.

## Phase 1 — Inventory (read-only) ✅ Done

Deliverable: `docs/fork/INVENTORY.md` with:

- Every create path per resource in the ENTITLEMENTS.md catalog
  (`rg -n "def create|\.create!|Builder" app/controllers app/builders app/services enterprise custom` per model).
- Every job/listener that creates capacity resources.
- UI entry points (create buttons/forms) per resource.
- Risky bypass paths (channel onboarding → Inbox, OAuth → Integrations::Hook,
  invites → AgentBuilder) with file:line.
- Existing limit UI (enterprise banners/paywalls) worth reusing.

## Phase 2 — Overlay bootstrap + entitlement service ✅ Done

1. Create `custom/` skeleton (ARCHITECTURE.md layout) and the
   `config/application.rb` bootstrap block; verify injector picks up a trivial
   `Custom::Account` module before writing real logic.
2. Wire `spec/custom/` into RSpec (mirror `spec/enterprise` inclusion).
3. Implement `Custom::Account::PlanUsageAndLimits` (extend `usage_limits`,
   extend the `validate_limit_keys` schema) and `Custom::EntitlementService`.
4. Specs: limit resolution chain (per-account jsonb → global config →
   unlimited), boundary decisions, denial result shape.

Gate: `docker compose run --rm rails bundle exec rspec spec/custom` green;
`docker compose run --rm rails bundle exec rspec spec/models/account_spec.rb spec/enterprise` green (no regression).

## Phase 3 — Backend guards ✅ Done

Per resource in the ENTITLEMENTS.md catalog (do one resource end-to-end, then
replicate the pattern):

1. `Custom::QuotaEnforcement` controller concern with
   `render_quota_exceeded(result)` (402, additive shape) — once.
2. Controller guard (`before_action`) via `Custom::<Controller>` module.
3. Model-level guard where multiple create paths exist (Inbox, AgentBot,
   Label, Integrations::Hook) via `Custom::<Model>` validation on create.
4. Denial logging in the service.
5. Request specs: under cap / at cap / edit at cap / delete-then-create.
6. Bypass specs for the risky paths found in Phase 1.

Gate: full backend suite `docker compose run --rm rails bundle exec rspec`
green, plus `docker compose run --rm rails bundle exec rubocop`.

## Phase 4 — Provisioning glue ✅ Done

- Confirm the control plane can set `accounts.limits` through the existing
  enterprise accounts API / Super Admin (no new endpoints).
- Script a reference tenant-provisioning flow (Platform API: account → admin
  user → inbox → webhook → agent bot + token) as a runnable doc/example, not
  production code in this repo.

## Phase 5 — AI loop verification (contract side) ◑ Contract done; manual run outstanding

This repo's responsibility is only that contracts hold:

- Webhook specs: signing headers present and correct
  (`spec/lib/webhooks/trigger_spec.rb` area), `message_created` payload has
  `message_type`, `private`, sender info, `account.id`, `X-Chatwoot-Delivery`
  set.
- Message-create API spec with a bot/agent token posting `outgoing` succeeds.
- Manual loop test against a local orchestrator stub (per AI_REPLY_LOOP.md):
  incoming → webhook → stub → API reply → exactly one reply, no self-trigger.

## Phase 6 — UI adaptation ✅ Done

- Extend the account payload/store with the new `usage_limits` keys (verify
  serializer path found in Phase 1).
- `useQuota(resource)` composable; disable-at-cap + `current/limit` + upgrade
  copy (i18n in `en.json`, brand via `useBranding`); render backend `error`
  on 402 everywhere.
- `docker compose run --rm vite pnpm eslint` and `pnpm test` green.

## Phase 7 — Branding pass ◑ Copy/config done; assets + deploy config deferred

Per WHITE_LABEL.md, then full build + click-through. Copy, installation configs,
mailers, and MFA issuer are done; the deferred items (Layer-3 brand assets and
deploy-time config values) are listed under **Remaining work** above and in
WHITE_LABEL.md's "Deferred" section.

## Merge checklist (all must pass)

- [ ] Existing webhook events fire with unchanged names/payloads/headers.
- [ ] Existing message create / conversation create / listing routes:
      unchanged paths, request shapes, success responses.
- [ ] No public route renamed; no response key removed or renamed.
- [ ] Quota enforced in backend for every catalog resource, including bypass
      paths; UI is mirror only.
- [ ] Denials: 402 + additive shape + i18n message + structured log.
- [ ] AI trigger cannot self-loop (`message_type` filter proven by test).
- [ ] Duplicate webhook delivery produces no duplicate reply (orchestrator
      test) and no contract change here.
- [ ] Branding broke no asset paths or routes.
- [ ] `docker compose run --rm rails bundle exec rspec` fully green;
      `rubocop` clean; `pnpm eslint` + `pnpm test` clean.
- [ ] `docs/fork/error-log/` updated for every issue fixed en route.
- [ ] OSS/enterprise files untouched except the documented
      `config/application.rb` bootstrap (verify with `git diff --stat develop`).
