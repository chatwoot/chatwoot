# Fork Documentation Index

This directory holds the architecture and implementation docs for turning this
Chatwoot fork into the conversation layer of a multi-tenant SaaS (quota
enforcement, AI reply loop, white-label) **without breaking any upstream
Chatwoot API or webhook contract**.

Read in this order:

| File | Purpose |
| --- | --- |
| [SPEC.md](./SPEC.md) | The optimized product/engineering spec (source of truth for scope and acceptance) |
| [ARCHITECTURE.md](./ARCHITECTURE.md) | Target architecture, verified extension points in this codebase, `custom/` overlay layout |
| [ENTITLEMENTS.md](./ENTITLEMENTS.md) | Quota/entitlement design: limit catalog, policy service, error contract, UI rules |
| [AI_REPLY_LOOP.md](./AI_REPLY_LOOP.md) | Webhook → LangGraph → message-API reply loop: signature verification, idempotency, loop prevention |
| [WHITE_LABEL.md](./WHITE_LABEL.md) | Config-first branding pass |
| [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md) | Phased execution plan with per-phase commands, tests, and merge checklist |
| [INVENTORY.md](./INVENTORY.md) | Phase 1 output: every create path per quota resource, bypass risks, existing limit plumbing |
| [PROVISIONING.md](./PROVISIONING.md) | Phase 4 output: reference tenant provisioning flow (Platform API, limits, AI-loop plumbing) |
| [CHATWOOT_ENGINE_INTEGRATION.md](./CHATWOOT_ENGINE_INTEGRATION.md) | **Self-contained contract for the external repo** (NestJS control plane + AI orchestrator): auth, provisioning, quotas, agentic-AI limit, and the signed webhook reply loop. Hand this file to that repo. |
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
