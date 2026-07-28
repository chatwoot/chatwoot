# What the Meta CRM Fork Changes vs. Upstream Chatwoot

**Baseline:** `upstream` = `github.com/chatwoot/chatwoot` (the "default repo").
**Fork:** `origin` = `github.com/mujibulhaquetanim/meta-crm`.

This file is the single, auditable inventory of **every** change the fork makes on
top of upstream Chatwoot, so the diff stays small, reviewable, and friendly to
pulling future upstream releases. It is generated from an actual
`git` audit, not from memory — re-run the commands in
[§8](#8-how-to-reproduce-this-audit) after any upstream merge.

## 0. Verdict (the rule you asked me to keep)

> **Do not modify Chatwoot's default/core flow. Nothing default may break. Stay
> pull-request friendly with the original repo.**

**Status: held.** Concretely:

- **No core logic was rewritten.** Every touch to an OSS (`app/`, `lib/`,
  `config/`) or `enterprise/` file is one of exactly four kinds:
  1. a canonical `Foo.prepend_mod_with('Foo')` / `include_mod_with` extension
     point at the bottom of a file (the *standard Chatwoot pattern*, a no-op on
     upstream),
  2. the one-time `custom/` autoload bootstrap in `config/application.rb`,
  3. an **additive** frontend / i18n line that is **inert by default** (empty
     config, `false` prop, or a brand string that only differs when the
     installation is branded), or
  4. a **dev-environment / tooling** file that ships no runtime behavior
     (Docker compose, devcontainer, `database.yml`, `AGENTS.md`) plus one
     enterprise spec whose setup the fork's model guard invalidated — all
     catalogued in [§6](#6-dev-environment-tooling-and-spec-adjustments).
- **All real behavior lives in the `custom/` overlay** (injected via
  `prepend_mod_with`, same mechanism as `enterprise/`), plus `docs/fork/` and
  `spec/custom/`. These are fork-owned trees that upstream never touches → **zero
  merge conflicts** there.
- **Every added behavior is opt-in.** With no per-account `limits`, no
  `ENABLE_SSO_ONLY_LOGIN`, no `EXTERNAL_LOGIN_URL`, and no branding configs set,
  the app behaves byte-for-byte like stock Chatwoot (proven by the upstream +
  `spec/custom` suites staying green).
- **Frozen public contracts** (route paths, webhook event names/payloads,
  `X-Chatwoot-*` headers, existing JSON keys) are only ever **extended
  additively** — never renamed or removed.

## 1. Change map at a glance

| Layer | Location | Conflict risk on upstream pull | Nature |
| --- | --- | --- | --- |
| Fork overlay | `custom/**` | none (upstream has no `custom/`) | all real fork logic |
| Fork docs | `docs/fork/**` | none | this documentation + error log |
| Fork specs | `spec/custom/**` | none | fork test suite |
| Extension points | ~15 OSS/ent files, **+1–2 lines each** | trivial (append-only at EOF) | canonical `prepend_mod_with` hooks |
| Bootstrap | `config/application.rb` | trivial (adjacent to enterprise lines) | eager-load + view path for `custom/` |
| Frontend integration | ~13 OSS Vue/JS files | low (additive, isolated) | banner mount, quota UI, SSO redirect |
| Branding | `config/locales/en.yml` + ~16 `en*.json`/Vue literals | low (value-only swaps) | "Chatwoot" → "Meta CRM" display copy |
| Dev env & tooling | `docker-compose.yaml`, `.devcontainer/devcontainer.json`, `config/database.yml`, `AGENTS.md` (+ net-new `docker-compose.rspec.yaml`) | **moderate** — the largest conflict surface after `db/schema.rb`; upstream edits these occasionally | Docker-only Neon/Upstash dev stack; no runtime behavior ([§6](#6-dev-environment-tooling-and-spec-adjustments)) |
| Spec adjustment | `spec/enterprise/.../accounts/agents_controller_spec.rb` | low | setup made cap-exact — the fork's model guard forbids over-cap creation ([§6](#6-dev-environment-tooling-and-spec-adjustments)) |

## 2. Fork-owned trees (new files — no upstream overlap)

Everything here is net-new; pulling upstream can never conflict with it.

- **`custom/` overlay** — the entire feature surface:
  - Entitlements: `custom/app/models/custom/account/plan_usage_and_limits.rb`,
    `custom/app/services/custom/entitlement_service.rb`,
    `custom/app/controllers/custom/concerns/quota_enforcement.rb`,
    `custom/app/models/custom/concerns/quota_guard.rb`.
  - Model create-guards: `custom/app/models/custom/{inbox,team,webhook,label,agent_bot,automation_rule,account_user}.rb`,
    `custom/app/models/custom/integrations/hook.rb`,
    `custom/app/models/custom/concerns/custom_attribute_definition.rb`.
  - Controller guards: `custom/app/controllers/custom/api/v1/accounts/*` (teams,
    webhooks, labels, automation_rules, custom_attribute_definitions, agent_bots,
    integrations/hooks).
  - Platform-managed flag permit: `custom/app/controllers/custom/platform/api/v1/account_users_controller.rb`.
  - Platform account merge-patch: `custom/app/controllers/custom/platform/api/v1/accounts_controller.rb`
    (`custom_attributes` on update is RFC 7386-style merge-patch so the control
    plane's sparse agentic-usage writeback can't wipe Chatwoot-owned account
    attributes; `limits` keeps upstream replace semantics).
  - Agents list scoping: `custom/app/controllers/custom/api/v1/accounts/agents_controller.rb`
    (overrides `agents` → excludes `platform_managed` seats from the list, the
    create-guard count, and edit/destroy lookup, ADR-0005).
  - Limits read API + agentic-AI display:
    `custom/app/controllers/custom/enterprise/api/v1/accounts_controller.rb`
    (also re-derives `agents.consumed` from the entitlement service so the UI
    count excludes platform-managed infra).
  - Auth lockdown: `custom/app/controllers/custom/devise_overrides/sessions_controller.rb`
    (password/MFA) + `.../omniauth_callbacks_controller.rb` (Google OAuth + SAML),
    sharing `custom/app/controllers/custom/concerns/sso_only_login.rb`.
  - Super Admin bootstrap: `custom/app/services/custom/super_admin_bootstrap.rb`
    (env-driven first-boot operator + seed removal + baseline hardening; run via the
    net-new task `lib/tasks/fork/super_admin.rake` → `fork:super_admin:bootstrap`).
  - Branding/MFA/mailers: `custom/app/services/custom/branding_setup.rb`,
    `custom/app/services/custom/mfa/management_service.rb`,
    `custom/app/mailers/custom/administrator_notifications/account_notification_mailer.rb`,
    `custom/app/views/administrator_notifications/**/*.liquid`.
- **`docs/fork/`** — spec, architecture, entitlements, AI loop, provisioning,
  white-label, the external integration contract, this file, and `error-log/`.
- **`spec/custom/`** — fork test suite mirroring OSS layout.
- **`db/migrate/20260704000000_add_platform_managed_to_platform_resources.rb`** —
  net-new migration adding an **additive** `platform_managed` boolean (default
  `false`, `null: false`) to `agent_bots`, `webhooks`, `account_users` (ADR-0005).
  New timestamped migration files never conflict; `db/schema.rb` picks up the three
  columns and is regenerated on migrate.

## 3. Sanctioned OSS/enterprise extension points (one line each, no-op upstream)

Each of these adds only the canonical Chatwoot injector hook at the bottom of the
file. Upstream ships this exact pattern across the codebase, so these are the
lowest-risk possible edits.

| File | Added line | Injects |
| --- | --- | --- |
| `app/models/team.rb` | `Team.prepend_mod_with('Team')` | `Custom::Team` (quota guard) |
| `app/models/webhook.rb` | `Webhook.prepend_mod_with('Webhook')` | `Custom::Webhook` |
| `app/models/label.rb` | `Label.prepend_mod_with('Label')` | `Custom::Label` |
| `app/models/agent_bot.rb` | `AgentBot.prepend_mod_with('AgentBot')` | `Custom::AgentBot` |
| `app/models/integrations/hook.rb` | `Integrations::Hook.prepend_mod_with(...)` | `Custom::Integrations::Hook` |
| `app/controllers/api/v1/accounts/teams_controller.rb` | `...TeamsController.prepend_mod_with(...)` | quota `before_action` |
| `app/controllers/api/v1/accounts/webhooks_controller.rb` | same pattern | quota `before_action` |
| `app/controllers/api/v1/accounts/labels_controller.rb` | same pattern | quota `before_action` |
| `app/controllers/api/v1/accounts/automation_rules_controller.rb` | same pattern | quota (incl. `clone`) |
| `app/controllers/api/v1/accounts/custom_attribute_definitions_controller.rb` | same pattern | quota `before_action` |
| `app/controllers/api/v1/accounts/agent_bots_controller.rb` | same pattern | quota `before_action` |
| `app/controllers/api/v1/accounts/integrations/hooks_controller.rb` | same pattern | quota `before_action` |
| `app/controllers/platform/api/v1/account_users_controller.rb` | `...AccountUsersController.prepend_mod_with(...)` | `Custom::...AccountUsersController` (permit `platform_managed`, ADR-0005) |
| `app/controllers/platform/api/v1/accounts_controller.rb` | `...AccountsController.prepend_mod_with(...)` | `Custom::...AccountsController` (`custom_attributes` merge-patch on update) |
| `enterprise/app/controllers/enterprise/api/v1/accounts_controller.rb` | `...AccountsController.prepend_mod_with(...)` | limits endpoint + agentic-AI |
| `app/mailers/administrator_notifications/account_notification_mailer.rb` | `...AccountNotificationMailer.prepend_mod_with(...)` | branded subjects |
| `app/services/mfa/management_service.rb` | `Mfa::ManagementService.prepend_mod_with(...)` | branded TOTP issuer |

> Models that already had the hook upstream — `inbox.rb`, `account_user.rb`,
> `custom_attribute_definition.rb`, `automation_rule.rb`, and
> `devise_overrides/sessions_controller.rb` — needed **no hook edit**; the fork
> just supplies the `Custom::*` module they resolve. (`account_user.rb`,
> `agent_bot.rb`, and `webhook.rb` do carry a regenerated schema-annotation
> block documenting the fork's `platform_managed` column — that annotation is
> the honest description of the fork's own migration and stays. Annotation
> refreshes must **not** spill into models the fork's migrations don't touch;
> collateral churn in `category.rb`, `platform_banner.rb`,
> `enterprise/.../captain/document.rb`, and `enterprise/.../company.rb` was
> reverted to upstream text on 2026-07-10.)

## 4. The one bootstrap edit (`config/application.rb`, +6 lines: 2 code + 4 comment)

Mirrors the existing `enterprise/` wiring for the `custom/` folder:

```ruby
config.eager_load_paths += Dir["#{Rails.root}/custom/app/**"]   # load overlay
config.paths['app/views'].unshift('custom/app/views')           # branded mailer views
```

This is the only multi-line OSS edit, and it sits directly beside the identical
enterprise lines — the intended, documented seam (see `ARCHITECTURE.md`).

## 5. Additive frontend & branding (no Ruby overlay exists for Vue/JS)

Vue/JS cannot be injected via `prepend_mod_with`, so these are direct edits — but
all are **additive and inert by default**:

- **Banner mount** — `app/javascript/dashboard/App.vue` (+3): import + register +
  `<AgenticAiLimitBanner v-if="hideOnOnboardingView" />`. The banner itself lives
  in the fork-only dir `app/javascript/dashboard/fork/AgenticAiLimitBanner.vue`
  and renders nothing unless an `agentic_ai` cap is set and reached.
- **Quota UI composable** — new files
  `app/javascript/dashboard/composables/useQuota.js` and
  `.../i18n/locale/en/quota.json` (+ one register line in `.../en/index.js`).
- **At-cap disabling** — the seven settings list pages (`agents`, `teams`,
  `labels`, `attributes`, `automation`, `agentBots`, `integrations/Webhooks`) and
  the three `IntegrationHooks*.vue` components gained `:disabled="atQuotaLimit"` +
  `:title="quotaTitle"` (props default `false`/`undefined` → identical to
  upstream until a cap is hit). `agents/Index.vue` uses `useQuota('agents')`, whose
  `consumed` now excludes platform-managed infra (backend override above).
- **SSO-expiry redirect** — `app/javascript/v3/views/login/Index.vue` (+6) reads
  `window.globalConfig?.EXTERNAL_LOGIN_URL` (populated by
  `DashboardController#app_config`) and bounces bare/expired logins to the
  external app. Empty config → no redirect.
- **`EXTERNAL_LOGIN_URL` exposure** — `app/controllers/dashboard_controller.rb`
  (+1): one additive key in `app_config`, defaulting to `''`.
- **Branding copy** — `config/locales/en.yml` (new `errors.quota.*` /
  `errors.sso_only_login` keys + "Chatwoot"→"Meta CRM" value swaps) and ~16
  frontend files (`i18n/locale/en/*.json` for dashboard/survey/widget plus a few
  Vue/JS string literals in `Code.vue`, `Widget.vue`, `ArticleSearch/Header.vue`,
  `SenderNameExamplePreview.vue`, `Mfa*.vue`, `CampaignEmptyStateContent.js`,
  `survey/views/Response.vue`). **Value-only** — every JSON key and interpolation
  variable (`{consumed}`, `{selectedChannelName}`, …) is unchanged, so upstream
  key lookups never break.

None of these alter routing, request/response shapes, or webhook payloads.

## 6. Dev environment, tooling, and spec adjustments

Non-runtime files the fork modifies for the Docker-only Neon/Upstash dev setup.
These are the **largest textual-conflict surface after `db/schema.rb`** — upstream
edits them occasionally — so they are catalogued here and should be kept as close
to upstream's text as the setup allows:

- **`docker/dockerfiles/rails.Dockerfile` / `docker/dockerfiles/vite.Dockerfile`**
  — one line each: `FROM chatwoot:development` became
  `ARG BASE_IMAGE=chatwoot:development` + `FROM ${BASE_IMAGE}`. **The default is
  upstream's original value**, so an upstream build that passes no build-arg
  behaves exactly as before and the conflict surface stays one line. Compose
  passes `BASE_IMAGE: mesh-crm:development` so the fork builds and runs its own
  tags (`mesh-crm:development`, `mesh-crm-rails:development`,
  `mesh-crm-vite:development`) instead of squatting on the `chatwoot:*` names
  used by upstream's published images.
- **`docker-compose.yaml`** — rewritten for the external-Postgres dev stack
  (Neon via `POSTGRES_*` in `.env`, no local `postgres` service, per-repo build
  targets). **Redis and mailhog are local services again** — the 2026-07-27
  entry below covers why: they were dropped in the original rewrite while
  `.env` still addressed them by their compose hostnames. `rails` and `sidekiq`
  gate on `redis: condition: service_healthy`, which matters because `sidekiq`
  declares no `entrypoint:` and therefore has no wait loop of its own. Also
  carries two env guards born from error-log entries:
  `ANNOTATERB_SKIP_ON_DB_TASKS=1` on `rails` (stops `db:migrate` from
  re-annotating OSS/enterprise models — the annotation-spill root cause) and
  `VITE_RUBY_HOST=0.0.0.0` on `vite` (dev server otherwise binds
  container-localhost and host asset requests reset). Expect conflicts when
  upstream reworks its compose file; resolve by re-applying the fork's stack on
  top of upstream's new baseline.
- **`docker-compose.rspec.yaml`** — net-new (no conflict risk): the isolated,
  tmpfs-backed test stack (see `AGENTS.md` / error-log 2026-07-02 entries for
  why specs must never run against the `rails` service).
- **`config/database.yml`** — adds `sslmode` (required by Neon) and moves
  shared connection keys into `default:`. Formatting was normalized in the
  process; if upstream edits this file, prefer taking upstream's text and
  re-adding only the `sslmode` line and env-var defaults.
- **`.devcontainer/devcontainer.json`** — ports/services adjusted to the same
  Docker-only stack.
- **`AGENTS.md`** — a fork-development section **appended** after upstream's
  content (additive; `CLAUDE.md` symlinks to it).
- **`spec/enterprise/controllers/api/v1/accounts/agents_controller_spec.rb`** —
  the only upstream spec edited: its setup created agents **past** the cap,
  which `Custom::Concerns::QuotaGuard` makes unreachable, so setup now fills the
  account exactly **to** the cap (same assertion, inline comment explains why).
  This is a recurring class: future upstream specs that set up over-quota state
  will need the same one-line adjustment after a sync.

## 7. Guarantee: default flows are untouched when the fork is "off"

| Default flow | Stays intact because |
| --- | --- |
| Create agent/inbox/team/webhook/… | Guard only denies when a **cap is set and reached**; unset ⇒ `ChatwootApp.max_limit` ⇒ never denies. Only a *new* 402 failure mode is added; the 201 success path is unchanged. |
| Native email/password + MFA login | `Custom::DeviseOverrides::SessionsController#create` is a straight `super` unless `ENABLE_SSO_ONLY_LOGIN` is truthy. |
| Google OAuth / SAML login | `Custom::DeviseOverrides::OmniauthCallbacksController#omniauth_success` is a straight `super` unless the same flag is on; blocked at the provider entry point before any token is minted (no OSS edit — the OSS controller already ships the `prepend_mod_with` hook). |
| `/app/login` page | Renders Chatwoot's form unless `EXTERNAL_LOGIN_URL` is set. |
| `GET /enterprise/api/v1/accounts/:id/limits` on **cloud** | Override returns `super` untouched; fork keys only appear on self-hosted (where it previously 404'd). |
| Webhooks / message API / all routes | Not modified at all — the AI loop is an external service riding stock contracts. |
| Branding | Every string falls back to "Chatwoot"/upstream default until a branding config/ENV is set. |

Proven by: `spec/custom` (83 examples, 0 failures) + upstream/enterprise suites
green with the overlay loaded, and `eslint` 0 errors.

## 8. How to reproduce this audit

```sh
git fetch upstream
BASE=$(git merge-base HEAD upstream/develop)        # true upstream divergence point
# All OSS/enterprise files the fork edits (exclude fork-owned trees):
git diff --name-only "$BASE"...HEAD | grep -vE '^(custom/|docs/fork/|spec/custom/)'
# Confirm each backend edit is an extension point / bootstrap / additive line:
git diff "$BASE"...HEAD -- app/models app/controllers app/services app/mailers config
```

Anything in that output that is **not** a `prepend_mod_with`/`include_mod_with`
line, the `application.rb` bootstrap, a documented additive line, or a
[§6](#6-dev-environment-tooling-and-spec-adjustments) dev-env/tooling file is
drift — move it into `custom/` (or revert it to upstream text) before merging.
Watch for **schema-annotation spill** in particular: `annotate` regenerating
comment blocks in models the fork's migrations don't touch is the drift class
that actually occurred (caught and reverted 2026-07-10).

## 9. Fixes applied while producing this audit (2026-07-03)

While verifying docs-vs-code, two contract-breaking bugs were found and fixed
**in a way that shrank, not grew, the OSS footprint** (full write-ups in
`error-log/`):

1. **`agentic_ai` limit key rejected by the schema** — the whole agentic-AI
   banner feature was unreachable. Fixed inside the overlay
   (`custom/app/models/custom/account/plan_usage_and_limits.rb`,
   `EXTERNAL_LIMIT_KEYS`); no OSS change.
   → `error-log/2026-07-03-agentic-ai-limit-key-rejected-by-schema.md`
2. **SSO-expiry redirect read the wrong global** — `Index.vue` used
   `window.chatwootConfig` instead of the populated `window.globalConfig`. Fixed
   at the source in `Index.vue` and **reverted** a redundant `vueapp.html.erb`
   edit, reusing the already-committed `DashboardController` wiring → one fewer
   core file touched.
   → `error-log/2026-07-03-external-login-url-not-exposed-to-frontend.md`
