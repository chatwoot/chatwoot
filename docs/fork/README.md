# Fork Documentation Index

This directory holds the architecture and implementation docs for turning this
Chatwoot fork into the conversation layer of a multi-tenant SaaS (quota
enforcement, AI reply loop, white-label) **without breaking any upstream
Chatwoot API or webhook contract**.

## Status at a glance (2026-07-04)

**Code-complete.** Every phase's code is shipped in the `custom/` overlay;
`spec/custom` is green. What's built:

- **Quota enforcement** — 9 capacity resources capped per tenant via
  `Account#usage_limits` + `accounts.limits` jsonb, guarded at controller **and**
  model layer so no create path (API, channel onboarding, OAuth callback, clone,
  Platform API) can bypass. Denials return the additive `402` shape.
- **Platform-managed exclusion** — the AI reply user (`role: agent`, ADR-0006), the
  ingest webhook, and the platform service admin `account_user` carry
  `platform_managed: true` and are excluded from the `agents`/`webhooks` counts, so
  the platform's own automation never costs a tenant a plan slot (ADR-0005).
- **Agentic-AI limit (display-only)** — the automated-workflow cap is enforced by
  the external NestJS backend; Chatwoot stores it in the limits jsonb
  (`EXTERNAL_LIMIT_KEYS`) and only surfaces a dashboard warning banner.
- **AI reply loop** — rides stock signed webhooks + the message-create API; the
  Chatwoot-side contract is locked by a spec. Orchestrator itself is external.
- **Auth lockdown** — optional `ENABLE_SSO_ONLY_LOGIN` refuses password/MFA
  (sessions overlay) **and** Google OAuth/SAML (omniauth overlay, shared
  `SsoOnlyLogin` gate) server-side; inert by default.
- **White-label** — copy, installation configs, mailers, and MFA issuer branded
  ("Meta CRM"); inert until configured.

**Not-code remaining:** brand asset files (logos/favicons/PWA), deploy-time
branding config values, and the manual cross-repo AI-loop run. See
[IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) for the phase-by-phase status
and [UPSTREAM_DIFF.md](./UPSTREAM_DIFF.md) for the exact change inventory.

> **Cross-repo AI-loop: LIVE-VERIFIED (2026-07-10, re-run; first proven
> 2026-07-04).** Against this Docker fork: fresh tenant provisioned via the
> backend (`account 75`), customer message posted through the Chatwoot API →
> signed webhook → external LangGraph agent → grounded (citation-validated)
> reply posted back into the same conversation; second message exercised the
> new **MCP live-data leg** (agent called a vendor MCP server tool and answered
> with live order status). No fork-side changes were needed — the loop rides
> stock signed webhooks + the message-create API exactly as specced. Details:
> meta-saas `docs/changes/2026-07-10-agentic-rag-upgrade-and-mcp.md`.

Read in this order:

| File | Purpose |
| --- | --- |
| [DEV_SETUP.md](./DEV_SETUP.md) | **Start here if you just cloned this repo** — fresh-clone runbook: `.env` (Neon) config and its two classic traps, correct image build order, schema load, starting the stack, how to *verify* it actually works (not just that containers are `Up`), login credentials, everyday container commands, and a troubleshooting table |
| [HOW_IT_WORKS.md](./HOW_IT_WORKS.md) | **Plain-English, diagram-first overview for non-technical readers** — what the product does, what we added, and how it talks to the external Next.js frontend and NestJS + LangGraph backend |
| [ROLES_AND_CONTROL.md](./ROLES_AND_CONTROL.md) | **Plain-English roles & control guide** — who controls what (super admin, brain, AI robot, human agent, tenant, customer), the limits we enforce, and why our additions won't cause upstream merge conflicts |
| [SUPER_ADMIN.md](./SUPER_ADMIN.md) | **Super Admin operator guide** — what the `/super_admin` console controls (accounts, users, Platform Apps/`PLATFORM_TOKEN`, installation configs, Sidekiq), who can reach it, how it's protected today (separate Devise scope, throttle, no MFA), how to create/rotate operators, and the production hardening checklist |
| [META_CHANNEL_ONBOARDING.md](./META_CHANNEL_ONBOARDING.md) | **Meta channel onboarding (Facebook/Instagram/WhatsApp)** — one platform Meta app + vendor OAuth (no per-vendor developer app); step-by-step platform setup, App Review/Advanced Access, per-vendor connect flow, permission reference, and the `CHANNELS_VIA_CHATWOOT` tie-in. Cross-checked against official Meta + Chatwoot docs (sources dated) |
| [VENDOR_DATA_HANDLING.md](./VENDOR_DATA_HANDLING.md) | **Plain-English data guide** — how each vendor (tenant) company's data is stored, isolated, secured, what reaches the AI, and how offboarding wipes it |
| [SPEC.md](./SPEC.md) | The optimized product/engineering spec (source of truth for scope and acceptance) |
| [SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md) | **Cross-repo architecture contract** — the five systems (Next.js / NestJS / LangGraph / Chatwoot / Meta), ownership matrix, and sequence diagrams (onboarding, AI reply, over-limit, handoff, quota). Authoritative for both repos. |
| [adr/](./adr/README.md) | **Architecture Decision Records** — the load-bearing cross-repo decisions (gateway, AI reply identity, webhook subscriptions, external agentic-AI enforcement, platform-managed resources) |
| [INTEGRATION_RECONCILIATION.md](./INTEGRATION_RECONCILIATION.md) | **meta-saas ↔ Chatwoot reconciliation** — verified match/divergence table between the two integration contracts + a local side-by-side dev runbook |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Target architecture, verified extension points in this codebase, `custom/` overlay layout |
| [ENTITLEMENTS.md](./ENTITLEMENTS.md) | Quota/entitlement design: limit catalog, policy service, error contract, UI rules |
| [AI_REPLY_LOOP.md](./AI_REPLY_LOOP.md) | Webhook → LangGraph → message-API reply loop: signature verification, idempotency, loop prevention |
| [WHITE_LABEL.md](./WHITE_LABEL.md) | Config-first branding pass |
| [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) | Phased execution plan with per-phase commands, tests, and merge checklist |
| [INVENTORY.md](./INVENTORY.md) | Phase 1 output: every create path per quota resource, bypass risks, existing limit plumbing |
| [PROVISIONING.md](./PROVISIONING.md) | Phase 4 output: reference tenant provisioning flow (Platform API, limits, AI-loop plumbing) |
| [CHATWOOT_ENGINE_INTEGRATION.md](./CHATWOOT_ENGINE_INTEGRATION.md) | **Self-contained contract for the external repo** (NestJS control plane + AI orchestrator): auth, provisioning, quotas, agentic-AI limit, and the signed webhook reply loop. Hand this file to that repo. |
| [UPSTREAM_DIFF.md](./UPSTREAM_DIFF.md) | **Complete inventory of every change vs. upstream Chatwoot** — how the fork stays additive, overlay-only, and pull-request friendly (audit + reproduce commands) |
| [UPSTREAM_SYNC.md](./UPSTREAM_SYNC.md) | **Runbook for syncing the fork with upstream** — when GitHub's Sync-fork button is safe ("Update branch") vs. destructive ("discard N commits"), the only real conflict (`db/schema.rb` version line) and how to resolve it, the push guards, and the step-by-step routine for every future sync |
| [error-log/](./error-log/README.md) | Running log of errors hit during implementation and how they were fixed |

## Ground rules (apply to every phase)

1. **Never edit OSS (`app/`, `lib/`) or `enterprise/` files when an overlay works.**
   Fork code lives in `custom/` and is injected via `prepend_mod_with` /
   `include_mod_with` (see ARCHITECTURE.md). This keeps upstream merges clean.
2. **No local Ruby.** Every Ruby/Rails/RSpec/RuboCop command runs inside Docker:
   `docker compose run --rm rails bundle exec <cmd>`. Frontend tooling runs in
   the vite container: `docker compose run --rm vite pnpm <cmd>`.
3. **Generate, don't hand-write, boilerplate.** Use `rails g migration ...`,
   `pnpm dlx ...`, etc. inside the containers instead of hand-crafting files
   whose shape a generator already knows.
4. **Every fixed error gets logged** in `docs/fork/error-log/` using the
   template there, before moving on.
5. **Public contracts are frozen**: route paths, webhook event names, webhook
   payload shape, `X-Chatwoot-Timestamp` / `X-Chatwoot-Signature` /
   `X-Chatwoot-Delivery` headers, and existing response shapes may only be
   extended additively, never renamed or removed.
