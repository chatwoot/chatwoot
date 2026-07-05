# Chatwoot Fork Spec (Optimized)

Compatibility-first multi-tenant SaaS fork: quota enforcement, AI reply loop,
white-label — built on Chatwoot's existing extension points instead of parallel
infrastructure.

> **Status (2026-07-03): implemented.** Every acceptance criterion below is met
> in code and covered by `spec/custom` (83 examples, green). This document
> remains the source of truth for *scope and intent*; for what shipped and
> where, see [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) (phase status)
> and [UPSTREAM_DIFF.md](./UPSTREAM_DIFF.md) (change inventory). Only non-code
> items remain: brand asset files, deploy-time config values, and the manual
> cross-repo AI-loop run.

## What changed vs. the original spec, and why

The original spec was written as if the fork needed a new entitlement system,
new webhook safety layer, and new branding layer from scratch. Code inspection
shows Chatwoot already ships most of the machinery, so the optimized spec
**reuses instead of rebuilds**:

1. **Entitlements already exist.** `Account#usage_limits`
   (`app/models/account.rb:149`), the `accounts.limits` jsonb column, the
   Enterprise plan-limit engine
   (`enterprise/app/models/enterprise/account/plan_usage_and_limits.rb`), and
   working guards on agent creation
   (`app/controllers/api/v1/accounts/agents_controller.rb:4-5`) and inbox
   creation (`app/helpers/api/v1/inboxes_helper.rb:118`). The fork **extends
   `usage_limits` with new resource keys** and adds guards to the remaining
   controllers — it does not build a second entitlement store.
2. **The error contract is already defined.** Existing quota rejections return
   HTTP 402 with `{ "error": "<message>" }` via `render_payment_required`
   (`app/controllers/concerns/request_exception_handler.rb:38`). Changing this
   to the originally proposed `quota_exceeded` shape would break the two guards
   that already exist. Instead: keep 402 + `error`, and **add fields
   additively** (`error_code`, `resource`, `current`, `limit`). Backward
   compatible, machine-readable.
3. **Fork code goes in `custom/`, not scattered edits.** Chatwoot's module
   injector natively supports a `custom/` overlay alongside `enterprise/`
   (`lib/chatwoot_app.rb:28-40`). All fork behavior lives there, so upstream
   merges stay conflict-free. One bootstrap change to `config/application.rb`
   is required to autoload it (see ARCHITECTURE.md).
4. **The AI reply loop needs zero Chatwoot code changes.** Outbound webhooks
   already sign with HMAC-SHA256 over `{timestamp}.{raw_body}` and send
   `X-Chatwoot-Delivery` (a per-delivery id — a ready-made idempotency key,
   `lib/webhooks/trigger.rb:54-63`). The AI orchestrator is an **external
   service**; Chatwoot-side work is limited to provisioning (webhook + bot
   token per tenant).
5. **Branding is config-first.** `INSTALLATION_NAME`, `LOGO`, `LOGO_DARK`,
   `LOGO_THUMBNAIL`, `BRAND_NAME`, `BRAND_URL`, `WIDGET_BRAND_URL`,
   `TERMS_URL`, `PRIVACY_URL` are already installation configs
   (`config/installation_config.yml`) editable from Super Admin, and the
   frontend has `useBranding` / `replaceInstallationName` for residual strings.
   The branding phase is mostly configuration + asset replacement, not code.
6. **Scope cuts.** Dropped from the original spec:
   - Guarding *assignment* flows (assigning agents/teams does not create
     capacity; only creation does).
   - New public webhook events (nothing in this spec needs one).
   - A standalone "policy service" abstraction independent of the Account
     model (the limits already hang off `Account`; a thin service wrapper is
     enough — see ENTITLEMENTS.md).

## Objective

Serve as the conversation layer for a multi-tenant SaaS while:

- keeping every existing API and webhook integration working unchanged,
- enforcing per-tenant resource caps in the backend (UI mirrors, never
  substitutes),
- supporting a webhook-driven AI reply loop through existing contracts,
- presenting the SaaS brand instead of Chatwoot.

## Hard compatibility rules (frozen contracts)

1. **Webhooks**: event names (`message_created`, `message_updated`,
   `conversation_created`, `conversation_updated`,
   `conversation_status_changed`, `contact_created`, `contact_updated`,
   typing events), payload shape, delivery/retry semantics, and the signing
   scheme (`X-Chatwoot-Timestamp`, `X-Chatwoot-Signature: sha256=<hmac>`,
   HMAC-SHA256 over `{timestamp}.{raw_request_body}`) are unchanged.
2. **APIs**: message create, conversation create/lookup, and all
   account/user/inbox/team/agent-bot routes keep their paths, request shapes,
   and success responses. Quota guards may only add a *new* failure mode:
   HTTP 402 with the extended error body below.
3. **Prefer internal hooks** (`Rails.configuration.dispatcher` events,
   listeners, jobs) over any new public surface.

## Quota enforcement

Enforced caps (per account): **agents, teams, inboxes, agent bots, webhooks,
labels, custom attribute definitions, automation rules, integrations
(`Integrations::Hook`)**. Existing caps for Captain responses/documents and
emails remain as-is.

Rules per resource:

- Count only active, account-scoped rows (exact count queries in
  ENTITLEMENTS.md).
- Deny **creation** at cap; keep edit and delete open so capacity can be
  reclaimed.
- Guard **every** create path: controller, background job, and any channel
  onboarding flow that creates the resource as a side effect. Where multiple
  paths exist (e.g. inboxes via channel controllers), enforce at the model
  layer so no path can bypass.
- Log every denial (structured, with account id, resource, current, limit)
  for observability.

Shared denial response (extends, does not replace, the existing contract):

```json
HTTP 402
{
  "error": "Your plan allows 3 agents.",
  "error_code": "quota_exceeded",
  "resource": "agents",
  "current": 3,
  "limit": 3
}
```

UI: show usage/limit near each list, disable (not hide) create actions at cap
with upgrade copy, and always surface the backend rejection message — the UI
is a mirror of enforcement, never the enforcement.

## AI reply loop (external orchestrator)

Flow: contact message → Chatwoot fires `message_created` webhook → orchestrator
verifies signature → filters (only `message_type == "incoming"`, not private,
sender is a Contact, not already processed) → LangGraph pipeline → reply
posted via the existing message-create API using a per-tenant bot/agent token
→ delivery marked processed.

Safety invariants (detailed in AI_REPLY_LOOP.md):

- **Loop prevention**: never react to outgoing/system/template messages or to
  messages authored by the bot identity itself.
- **Idempotency**: every delivery is assumed repeatable; dedupe on
  `X-Chatwoot-Delivery` + message id before queuing work.
- **Async**: webhook handler only verifies + enqueues; AI work happens in a
  queue worker; Chatwoot gets a fast 2xx.

## Permissions model

- **Super admin**: installation-level control, `/super_admin`, Platform APIs
  (self-hosted only), tenant provisioning.
- **Tenant admin**: manages one account within quota; no installation access.
- **Tenant agent**: works conversations; cannot create capacity resources.
- Enforcement lives in controllers/policies/jobs — menu hiding alone is never
  sufficient.
- **Auth entry point**: optional SSO-only lockdown (`ENABLE_SSO_ONLY_LOGIN`)
  makes the external stack's Platform SSO token the sole way into a tenant
  account — password, MFA-token, Google OAuth, and SAML are all refused
  server-side (session + omniauth controllers), never by UI hiding alone.
  Super admin uses a separate Devise scope and is unaffected. Inert by default.
  Contract in CHATWOOT_ENGINE_INTEGRATION.md §4.5–4.6.

## White-label

Cosmetic/copy-level only: installation configs, assets, `en.yml`/`en.json`
strings, mailer branding. No route, header, or payload renames for branding
purposes. Details in WHITE_LABEL.md.

## Acceptance criteria

The fork is done only when:

1. No tenant can exceed any configured cap through any create path (API, UI,
   job, channel onboarding).
2. All pre-existing webhook and API integrations behave identically
   (regression suite green).
3. The AI loop reads incoming messages and posts replies using only existing
   contracts, with no self-reply loops and no duplicate replies on redelivery.
4. UI limits mirror backend enforcement.
5. Branding shows the SaaS identity with no broken assets or routes.
6. The test matrix in IMPLEMENTATION_PLAN.md is green under
   `docker compose run --rm rails bundle exec rspec`.
