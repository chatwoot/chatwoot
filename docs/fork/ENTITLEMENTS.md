# Entitlements & Quota Enforcement

Design goal: one source of truth (`Account#usage_limits`), one guard pattern,
one error shape — applied uniformly to every capacity-creating resource.

> **Status (2026-07-03): shipped.** All nine resources in the catalog below are
> enforced. `Custom::Account::PlanUsageAndLimits` extends `usage_limits` + the
> jsonb schema; `Custom::EntitlementService` does counting/denial logging;
> `Custom::QuotaEnforcement` renders the 402; controller guards + `QuotaGuard`
> model validations cover every create path (including channel onboarding, OAuth
> callbacks, and automation-rule clone). Boundary, bypass, and denial-shape cases
> are covered in `spec/custom` (green). The imperative phrasing below ("must",
> "the override must") documents the rules the shipped code follows.
>
> **Flow:** `create request → Pundit authorize → controller quota before_action`
> (or, for multi-path resources, `model validate on: :create`) `→
> EntitlementService#check(resource)` (count vs. `usage_limits[resource]`) `→
> allow (201) | deny → render_quota_exceeded → 402 + additive body + structured
> log`.

## Limit sources

Fork quota keys resolve in exactly two steps:

1. `accounts.limits` jsonb (per-tenant — what the SaaS control plane sets at
   purchase/upgrade via the Platform API or Super Admin),
2. `ChatwootApp.max_limit` (effectively unlimited).

Deliberately **no** `GlobalConfig` `ACCOUNT_<RESOURCE>_LIMIT` fallback for the
fork keys (unlike upstream agents/inboxes): model guards run on every record
create, and the GlobalConfig lookup costs a Redis roundtrip per save and broke
upstream specs that mock GlobalConfig strictly (see error log,
2026-07-02 GlobalConfig strict-mock entry). Upstream's own `agents`/`inboxes`
keys keep their enterprise resolution chain untouched.

## Current plan catalog — what a new / free account gets

A brand-new tenant starts on the **Trial** (free, $0) plan. The control plane
(meta-saas) seeds three plans (`meta-saas/apps/api/prisma/seed.ts`); a tenant's
`TenantEntitlement` overrides win when set. `PlanLimitsSyncService` pushes the
**Chatwoot-enforced** subset (agents/teams/inboxes) into `accounts.limits` on
provisioning and on every plan change — which is why a trial account shows
`limits = {"teams" => 1, "agents" => 1, "inboxes" => 2}`.

| Cap | **Trial (free)** | Starter | Pro | Enforced by |
| --- | --- | --- | --- | --- |
| Agents | **1** | 3 | 25 | **Chatwoot** — `accounts.limits.agents` (402 quota modal) |
| Teams | **1** | 2 | 10 | **Chatwoot** — `accounts.limits.teams` |
| Inboxes (vendor) | **1** (+1 system → `inboxes: 2`) | 3 (→4) | 25 (→26) | **Chatwoot** — `accounts.limits.inboxes` |
| Messages / window | **500** | 5,000 | 50,000 | NestJS control plane |
| LLM tokens / window | **100,000** | 2,000,000 | 20,000,000 | NestJS control plane |
| Tool calls / window | **500** | 5,000 | 50,000 | NestJS control plane |
| KB documents | **20** | 200 | 2,000 | NestJS control plane |
| Allowed tools | **`kb_search`** | + `crm_lookup`, `order_lookup` | + `booking`, `ticketing` | NestJS policy engine |

Notes:

- **The `+1` system inbox** is the platform "AI Handoff" API inbox
  (`SYSTEM_RESERVED_INBOXES`), reserved on top of the plan so a `maxInboxes: 1`
  trial still lets the vendor create **1** of their own channels (see
  `plan-limits-sync.service.ts`).
- **"per window"** = a **rolling 15-day** usage window (`QUOTA_WINDOW_DAYS`,
  default 15). Exceeding messages/tokens/tool-calls flips the tenant's
  `aiEnabled` to `false` (reason `message_quota_exceeded` / `token_quota_exceeded`)
  → **the AI stops auto-replying**. The window renews and the block **self-lifts**;
  human replies in Chatwoot are never blocked and no data is deleted. This is the
  `agentic_ai` limit surfaced here display-only (see the last section) but enforced
  in NestJS.
- **None of these are login / access gates.** They cap capacity and automation, not
  whether you can open or sign into an account — see the next section.

## Not a limit: why a day-old account seems "inaccessible"

A common confusion: *"I registered an account yesterday and can't get into it today,
but creating a new one drops me straight into Chatwoot — is the free plan limiting
me?"* **No.** The account still exists with its normal caps; this is the **SSO-only
lockdown**, not a quota:

- `ENABLE_SSO_ONLY_LOGIN=true` → **native Chatwoot login is refused**. A tenant reaches
  Chatwoot **only** by bouncing through the meta-saas login, which mints a fresh
  Chatwoot session.
- That session **expires** (it's not a permanent login). A day later, navigating to
  Chatwoot directly can't sign you in, because native login is off.
- **Re-enter through the meta-saas dashboard** (`EXTERNAL_LOGIN_URL`, e.g.
  `http://localhost:3002/login`) with your vendor credentials — it re-bounces you into
  your **existing** account. "Opening a new account" simply runs that same fresh SSO
  bounce, which is why *that* lands you in Chatwoot.

See [`chatwoot-access-lockdown.md`](../../../meta-saas/docs/operations/chatwoot-access-lockdown.md)
for the lockdown mechanism and [`SUPER_ADMIN.md`](./SUPER_ADMIN.md) for operator access.

## Fork extension: `Custom::Account::PlanUsageAndLimits`

`custom/app/models/custom/account/plan_usage_and_limits.rb`, prepended onto
`Account` after the enterprise module:

- `usage_limits` → `super.merge(teams:, webhooks:, agent_bots:, labels:, custom_attribute_definitions:, automation_rules:, integrations:)`,
  each resolved with the same `get_limits(...)`-style chain.
- Override `validate_limit_keys` to extend the JSON schema: the enterprise
  schema uses `additionalProperties: false` with a fixed key list
  (`plan_usage_and_limits.rb:162-180`), so writing `{"teams": 5}` into
  `accounts.limits` **fails validation today**. The custom override must allow
  the new keys (call pattern: replicate the schema with the extended property
  list; do not loosen `additionalProperties`).

## Policy façade: `Custom::EntitlementService`

A thin, UI-independent, easily-mockable service so guards and jobs don't
re-implement counting:

```ruby
Custom::EntitlementService.new(account).check(:teams)
# => #<Result allowed: false, resource: :teams, current: 5, limit: 5>
```

Responsibilities: current count (per the catalog below), limit lookup via
`account.usage_limits`, allow/deny, and structured denial logging
(`Rails.logger.warn` with account_id/resource/current/limit). No HTTP, no UI.

## Resource catalog

"Guard layer" = where denial must be enforced so **no** path bypasses it.
Model-layer guards (a `validate ... on: :create` added via `Custom::<Model>`
concern) are used whenever more than one code path creates the row.

| Resource | Count query | Create paths | Guard layer |
| --- | --- | --- | --- |
| Agents | confirmed, non-blocked agent `account_users` (match existing `can_add_agent?` logic in `agents_controller.rb:96-101`) | `AgentsController#create/#bulk_create` (already guarded), invitation/`AgentBuilder` flows | Keep controller guard; add guard inside `AgentBuilder` so non-controller callers are covered |
| Teams | `account.teams.count` | `TeamsController#create` | Controller + model |
| Inboxes | `account.inboxes.count` (existing guard: `inboxes_helper.rb:118`) | `InboxesController#create` **and every channel controller** (`channels/`, `callbacks_controller`, instagram/tiktok/twitter onboarding) that builds an inbox | **Model-level on `Inbox`** (many paths); keep helper guard for the clean API error |
| Agent bots | `account.agent_bots.count` | `AgentBotsController#create`, platform API agent-bot create | Model-level on `AgentBot` |
| Webhooks | `account.webhooks.count` | `WebhooksController#create` | Controller + model |
| Labels | `account.labels.count` | `LabelsController#create`, inline label creation from conversation UI | Model-level on `Label` |
| Custom attribute definitions | `account.custom_attribute_definitions.count` | `CustomAttributeDefinitionsController#create` | Controller + model |
| Automation rules | `account.automation_rules.count` | `AutomationRulesController#create` (+ clone/copy action if present) | Controller + model |
| Integrations | `account.hooks.count` (`Integrations::Hook`) | `Integrations::HooksController#create`, OAuth callback flows that create hooks | Model-level on `Integrations::Hook` |

Notes:

- Edits and deletes stay unrestricted (capacity can always be reclaimed).
- Model-level guard raises/records a validation error; controllers translate
  it (or their own before_action) into the shared 402 response.
- Verify each "create paths" cell with
  `rg -n "<Model>.create|<model>s.build|<Model>Builder" app enterprise custom`
  during Phase 1 (inventory) — the table is the starting map, not gospel.
- **Platform-managed exclusion (see below):** the `agents`, `agent_bots`, and
  `webhooks` counters are scoped to `where(platform_managed: false)`, so platform
  infrastructure never consumes a tenant slot.

## Platform-managed resources (infrastructure exclusion)

Some resources provisioned inside a tenant account are **platform
infrastructure**, not tenant-billable seats: the **AI reply user** (a
`role: agent` `account_user`, ADR-0006), its **account webhook** (orchestrator
ingest), and the platform's **automation service admin `account_user`** (behind
`USER_TOKEN`). Charging a plan slot for the platform's own automation is wrong — a
"3 agents / 2 webhooks" plan must give the tenant all of those, not fewer.

These carry `platform_managed: true` (column on `agent_bots`, `webhooks`,
`account_users`; default `false`) and are **excluded from entitlements entirely**:

- **Counted out** — `RESOURCE_COUNTERS` for `agents`/`agent_bots`/`webhooks` filter
  `where(platform_managed: false)`. For `agents` this is enforced end-to-end:
  `Custom::Api::V1::Accounts::AgentsController#agents` scopes the tenant-facing
  finder to `platform_managed: false`, so infra is excluded from the **agents list**
  (`index`), the **create-guard count** (`can_add_agent?` builds on the same
  finder), **edit/destroy lookup** (`fetch_agent` → 404 on an infra id, protecting
  the service admin whose token is the account credential), and the limits
  endpoint's `agents.consumed` (re-derived via `Custom::EntitlementService`).
- **Never blocked** — both guard layers short-circuit for a platform-managed
  create: the model guard (`QuotaGuard#ensure_quota_capacity`) and the controller
  guards (`check_webhooks_quota` / `check_agent_bots_quota`). So infrastructure
  provisions even when the tenant is at their cap.

On the Application API (`webhooks`/`agent_bots`), the flag is honored **only when
the acting identity is itself platform-managed** — `Current.account_user.platform_managed?`
(`Custom::Concerns::PlatformActor`). Any other caller, including a tenant
`administrator`, has the `platform_managed` key stripped from permitted params, so
they cannot self-exempt and the resource still counts against the plan. The
Platform-API `account_users` create sets the flag directly and is safe by
construction (super-admin platform token only). Tenant-created resources omit the
flag and count normally — the change is fully backward compatible.
See [ADR-0005](./adr/0005-platform-managed-resources.md).

## Error contract

Additive extension of the existing `render_payment_required` behavior — same
status (402), same `error` key, new machine-readable fields:

```json
{
  "error": "Your plan allows 3 agents.",
  "error_code": "quota_exceeded",
  "resource": "agents",
  "current": 3,
  "limit": 3
}
```

Implement once as `render_quota_exceeded(result)` in a
`Custom::QuotaEnforcement` controller concern; never inline the JSON.
The two pre-existing guards (agents, inboxes) may be migrated to the new
renderer **only** because the change is additive (same status, `error` key
preserved).

The message string goes through i18n (`en.yml`), e.g.
`quota.exceeded: "Your plan allows %{limit} %{resource}."`.

## UI rules

- Read usage from the backend (`usage_limits` is already serialized on the
  account payload for agents/inboxes — extend the same serializer path for
  the new keys; verify in `app/views/api/v1/accounts/` / account store module).
- At cap: **disable** create buttons with a tooltip showing `current/limit`
  and upgrade copy (i18n via `en.json`, brand-safe via `useBranding`).
- Always render the backend `error` message on 402 — UI state can be stale.
- One shared composable (e.g. `useQuota(resource)`) instead of per-component
  logic.

## Permissions interplay

Quota checks run **in addition to** Pundit policies, never instead of them.
Order in controllers: authenticate → authorize (policy) → quota → act.
Super-admin/platform paths (e.g. Platform API account creation) are
installation-level and not quota-guarded, but platform-created *tenant
resources* (agent bots) still hit model-level guards.

## Testing (see IMPLEMENTATION_PLAN.md for the full matrix)

- Service specs: boundary at `limit - 1`, `limit`, unlimited default, per-key
  override in `accounts.limits`.
- Request specs per resource: create under cap (201), at cap (402 with full
  error shape), edit at cap (200), delete frees capacity (next create 201).
- Bypass-path specs: channel-created inbox at cap fails; `AgentBuilder` at cap
  fails; OAuth-created hook at cap fails.

## Agentic-AI limit (externally enforced, display-only)

The agentic-AI (automated workflow) quota is **enforced by the external NestJS
backend**, not Chatwoot. Chatwoot only surfaces it so the dashboard can warn the
tenant. It rides the existing limits pipeline rather than a parallel store:

- Contract (control plane / NestJS writes via the Platform API, additively):
  - cap → `accounts.limits['agentic_ai']` (same jsonb as every other limit).
  - running usage → `accounts.custom_attributes['agentic_ai_usage']`.
- Because `validate_limit_keys` uses `additionalProperties: false`, `agentic_ai`
  must be whitelisted in the schema or the Platform API write is rejected (422).
  It lives in `Custom::Account::PlanUsageAndLimits::EXTERNAL_LIMIT_KEYS`, kept
  **separate from `QUOTA_RESOURCES`** on purpose: `EXTERNAL_LIMIT_KEYS` are
  schema-valid but get no counter, no `usage_limits` merge, and no create-guard —
  Chatwoot stores and displays them but never enforces them.
- `GET /enterprise/api/v1/accounts/:id/limits` (`Custom::Enterprise::Api::V1::AccountsController`)
  emits `agentic_ai: { allowed, consumed }` in the standard shape, but **only
  when a cap is set** — accounts without agentic AI get an unchanged response.
- UI: `dashboard/fork/AgenticAiLimitBanner.vue` reuses `useQuota('agentic_ai')`
  and renders a global warning banner (admins only) when `consumed >= allowed`.
  It is display-only — there is no Chatwoot-side create path or 402 for this
  resource (NestJS owns enforcement), so it has no `EntitlementService`
  counter/guard.
