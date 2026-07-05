# Fork Architecture

> **Status (2026-07-03): built as described.** The `custom/` overlay, the
> `config/application.rb` bootstrap, and the `spec/custom` wiring below all exist
> and are green. The bootstrap/layout sections read as instructions but document
> what is already in the tree — file paths match. Line-number anchors are from
> the `develop` snapshot; re-verify after upstream merges.

## System overview

```text
┌────────────────────┐   provisioning    ┌──────────────────────────────┐
│  SaaS control      │  (Platform API,   │  Chatwoot fork (this repo)   │
│  plane / billing   │──super admin)────▶│  system of record:           │
│  (external)        │                   │  accounts, inboxes, teams,   │
└────────────────────┘                   │  conversations, webhooks     │
        │ sets accounts.limits           │  + custom/ overlay:          │
        ▼                                │    entitlement guards        │
┌────────────────────┐  message_created  └──────────┬───────────────────┘
│  AI orchestrator   │◀──webhook (signed)───────────┘        ▲
│  (external service │                                       │
│  + LangGraph)      │──POST reply via message-create API────┘
└────────────────────┘
```

Three deployable units. Only the middle one is this repo. The control plane
and orchestrator talk to Chatwoot exclusively through **existing public
contracts** (Platform API, Application API, webhooks), which is what keeps the
fork upgrade-safe.

## Verified extension points in this codebase

Everything below was confirmed by inspection on branch `develop`; treat the
line numbers as anchors, re-verify after rebases.

| Mechanism | Location | What it gives us |
| --- | --- | --- |
| `custom/` overlay | `lib/chatwoot_app.rb:28-40` — `ChatwootApp.extensions` returns `%w[enterprise custom]` when `custom/` exists | Fork modules injected via `prepend_mod_with` / `include_mod_with` without touching OSS or enterprise files |
| Module injector | `config/initializers/01_inject_enterprise_edition_module.rb` (iterates `ChatwootApp.extensions`) | `Custom::Foo` modules auto-prepend onto `Foo` |
| Usage limits (OSS) | `app/models/account.rb:149` `usage_limits` → `{ agents:, inboxes: }` defaults to `ChatwootApp.max_limit` | The hash every guard reads |
| Usage limits (plan engine) | `enterprise/app/models/enterprise/account/plan_usage_and_limits.rb` | Per-account `limits` jsonb → global config (`ACCOUNT_<NAME>_LIMIT`) → unlimited fallback chain; jsonb-schema validation of `accounts.limits` keys (`validate_limit_keys`, note `additionalProperties: false` — must be extended for new keys) |
| Existing guards | `app/controllers/api/v1/accounts/agents_controller.rb:4-5,90-101`; `app/helpers/api/v1/inboxes_helper.rb:118-121` | The guard pattern to replicate: `before_action :validate_limit` → `render_payment_required` |
| Error rendering | `app/controllers/concerns/request_exception_handler.rb:38-40` → 402 `{ error: message }` | The response contract quota denials must stay compatible with |
| Webhook signing | `lib/webhooks/trigger.rb:54-63` — `X-Chatwoot-Timestamp`, `X-Chatwoot-Signature: sha256=<HMAC-SHA256(secret, "ts.body")>`, `X-Chatwoot-Delivery` | Everything the AI orchestrator needs for verification + idempotency |
| Internal events | `Rails.configuration.dispatcher.dispatch(...)` + `app/listeners/` | Internal hooks if the fork ever needs its own domain events (prefer these over new public webhooks) |
| Branding configs | `config/installation_config.yml:17-53` (`INSTALLATION_NAME`, `LOGO*`, `BRAND_*`, `TERMS_URL`, `PRIVACY_URL`) + `shared/composables/useBranding` | White-label without code changes |
| Limits admin API | `enterprise/app/controllers/enterprise/api/v1/accounts_controller.rb` (updates `accounts.limits`) + Super Admin console | How the control plane sets per-tenant caps |

## The `custom/` overlay

### Bootstrap (one-time; sanctioned OSS edits are this block plus canonical one-line `prepend_mod_with` extension points at file bottoms)

`config/application.rb:43-53` eager-loads only `enterprise/`. Mirror those
lines conditionally for `custom/`:

```ruby
if ChatwootApp.custom?
  config.eager_load_paths += Dir["#{Rails.root}/custom/app/**"]
  config.eager_load_paths << Rails.root.join('custom/lib')
  # views/initializers only if the fork adds any:
  config.paths['app/views'].unshift('custom/app/views')
end
```

Also wire specs: add `spec/custom/` and confirm the default `.rspec`/
`spec_helper` glob picks it up (mirror how `spec/enterprise` is included —
check `spec/spec_helper.rb` / `.rspec` before assuming).

### Layout

```text
custom/
  app/
    models/custom/account/plan_usage_and_limits.rb   # extends usage_limits with new keys
    models/custom/concerns/...                       # model-level create guards (QuotaGuard)
    controllers/custom/api/v1/accounts/...           # controller quota-guard overrides
    controllers/custom/concerns/...                  # shared controller mixins (QuotaEnforcement, SsoOnlyLogin)
    controllers/custom/devise_overrides/...          # SSO-only auth lockdown (sessions + omniauth)
    controllers/custom/enterprise/api/v1/...         # limits endpoint + agentic-AI display
    services/custom/entitlement_service.rb           # thin policy façade (see ENTITLEMENTS.md)
    services/custom/branding_setup.rb                # white-label config upsert (see WHITE_LABEL.md)
    mailers/ + views/                                # branded transactional emails
  lib/
docs/fork/                                           # this documentation
spec/custom/                                         # fork specs, mirroring OSS layout
```

Naming rule: to extend class `Foo`, create module `Custom::Foo` and rely on the
injector; only place brand-new classes (not overrides) as plain classes under
`custom/app/`.

### Load-order note

`prepend_mod_with` applies `enterprise` then `custom` (order of
`ChatwootApp.extensions`), so `Custom::Account::PlanUsageAndLimits` can call
`super` to get the enterprise plan engine's result and merge fork keys on top.
The same ordering matters when both overlays touch one class: e.g.
`Custom::DeviseOverrides::OmniauthCallbacksController` prepends **ahead of**
`Enterprise::DeviseOverrides::OmniauthCallbacksController`, so its
`omniauth_success` runs first and can short-circuit the SSO-only lock before the
enterprise SAML handling (`super`) ever runs.

## Where each concern lives

| Concern | Lives in | Never in |
| --- | --- | --- |
| Quota limits & guards | `custom/` overlay + `accounts.limits` jsonb | UI-only checks, new tables |
| Auth lockdown (SSO-only) | `custom/` devise overlays (`sessions` + `omniauth_callbacks`) sharing `Custom::Concerns::SsoOnlyLogin`, gated by `ENABLE_SSO_ONLY_LOGIN` | UI-only hiding of login buttons; a second store of the flag |
| Tenant provisioning | External control plane via Platform API / Super Admin | Fork-specific provisioning routes |
| AI orchestration | External service (LangGraph) | Chatwoot controllers/jobs |
| Branding | Installation configs, assets, `en.yml`/`en.json`, `Custom::BrandingSetup`, `custom/app/views` mailer overrides | Route or header renames |
| Fork docs / error log | `docs/fork/` | — |

## Compatibility invariants

- Route paths, webhook event names/payloads, `X-Chatwoot-*` headers: frozen.
- Response shapes: extend additively only (new JSON keys are fine; renames,
  removals, and status-code changes on existing successes are not).
- Any change to a file also present in `enterprise/` must keep the enterprise
  behavior working (`rg -n "<ClassName>" app enterprise custom` before edits).
- Upstream merges: because fork logic is confined to `custom/`, `docs/fork/`,
  `spec/custom/`, the small `application.rb` bootstrap, and one-line
  `prepend_mod_with` extension points at OSS file bottoms, upstream pulls
  should conflict only on those lines — re-verify the anchors in this doc
  after every merge.
