# Entitlements & Quota Enforcement

Design goal: one source of truth (`Account#usage_limits`), one guard pattern,
one error shape — applied uniformly to every capacity-creating resource.

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
- `GET /enterprise/api/v1/accounts/:id/limits` (`Custom::Enterprise::Api::V1::AccountsController`)
  emits `agentic_ai: { allowed, consumed }` in the standard shape, but **only
  when a cap is set** — accounts without agentic AI get an unchanged response.
- UI: `dashboard/fork/AgenticAiLimitBanner.vue` reuses `useQuota('agentic_ai')`
  and renders a global warning banner (admins only) when `consumed >= allowed`.
  It is display-only — there is no Chatwoot-side create path or 402 for this
  resource (NestJS owns enforcement), so it has no `EntitlementService`
  counter/guard.
