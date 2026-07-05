# ADR-0006: The AI reply identity is a platform-managed `role: agent` account_user

**Status:** Accepted (2026-07-04)
**Supersedes:** [ADR-0002](./0002-agentbot-canonical-ai-identity.md) (system-managed
AgentBot as the canonical AI identity — never implemented, and made unnecessary by
ADR-0005).
**Builds on:** [ADR-0005](./0005-platform-managed-resources.md) (`platform_managed`
flag), [ADR-0001](./0001-chatwoot-single-messaging-gateway.md) (Chatwoot is the
single gateway).

## Context

ADR-0002 chose a system-managed **AgentBot** as the AI reply identity. Its **sole**
justification was quota hygiene: a plain `role: agent` user would consume one of the
tenant's paid `agents` seats, whereas an `AgentBot` is counted separately. At the time
that was the only way to keep the tenant's `agents` cap clean.

Two things changed after ADR-0002 was written:

1. **ADR-0002 was never implemented.** The running system provisions the AI reply
   identity as an ordinary per-tenant Chatwoot user with `role: agent` (created via
   the Platform API), added as an inbox member, whose `access_token` authors the
   `outgoing` AI replies. No `AgentBot` is created anywhere — verified: the meta-saas
   codebase has zero `agent_bots` provisioning, and a freshly provisioned live account
   has `agent_bots.count == 0`.
2. **ADR-0005 removed the only reason to prefer an AgentBot.** The `platform_managed`
   flag excludes flagged `account_users` from the `agents` count (and never blocks
   them). Stamping the AI reply user `platform_managed: true` makes it quota-clean
   **without** an AgentBot. Verified live on a provisioned account:
   `Custom::EntitlementService.new(account).usage(:agents).current == 0` while the AI
   user, the service-admin user, and the ingest webhook all exist.

So the AgentBot is unbuilt complexity whose one benefit is already delivered by a
mechanism we ship and rely on. Keeping it as "the canonical identity" in the docs
misdescribes the running system and adds a second identity concept (bot provisioning,
inbox attach, `BOT_TOKEN` lifecycle) for no architectural gain.

The platform architecture is unchanged and drives this choice: **meta-saas is the
agentic automation layer** — it authors every AI reply over Chatwoot's Application API,
and when a reply needs a human it uses Chatwoot's **native** assignment/handoff
features. The AI identity is just "the account the automation posts as"; the leanest
identity that is quota-clean and loop-safe wins.

## Decision

**The canonical AI reply identity is a dedicated per-tenant Chatwoot user with
`role: agent` and `platform_managed: true`.** There is no AgentBot.

- Provisioned via the Platform API during onboarding:
  `POST /platform/api/v1/users` → `POST /platform/api/v1/accounts/{id}/account_users`
  with `{ role: "agent", platform_managed: true }`, then added as an **inbox member**
  so its reply POSTs are authorized.
- Its `access_token` is stored **encrypted** on the platform side and used
  **exclusively** by the meta-saas orchestrator to author `outgoing` replies. It is
  never exposed to tenant admins or human agents.
- It is **excluded from every tenant entitlement count** by `platform_managed: true`
  (ADR-0005) — it never consumes an `agents` seat and is never blocked by the tenant's
  cap.
- The separate **service-admin** user (`role: administrator`, also `platform_managed:
  true`) is unchanged — it owns provisioning Application-API calls (create inbox,
  webhook, contacts, conversations). Both platform users are quota-exempt.
- **Human handoff is Chatwoot-native:** when the orchestrator escalates, meta-saas
  binds the handoff in place and notifies Chatwoot through its own API
  (assignment / private note / team routing) — it does **not** need a bot identity for
  this.

## Consequences

- **Docs now match reality.** The AgentBot / `BOT_TOKEN` concept is retired from the
  integration contract; the AI reply token is the platform-managed agent user's
  `access_token`.
- **Loop-safety is unchanged.** The agent user's replies are `message_type ==
  "outgoing"`, so they fail the incoming-only ingest filter — the AI never answers
  itself (verified live: a customer message produced exactly one `outgoing` reply and
  no re-entry).
- **Quota stays clean without plan gymnastics.** No AgentBot means no `agent_bots`
  slot to reserve; the retired ADR-0002 "size `agent_bots >= 1`" workaround stays
  retired, now for the agent-user path too.
- **Cosmetic trade-off (accepted):** the AI appears in Chatwoot's agent list as an
  agent named e.g. "Acme AI" rather than as a bot. Tenants operate from the meta-saas
  dashboard (not Chatwoot admin, per platform §7), and handoff agents seeing a
  platform-managed AI agent is acceptable. If bot-only semantics/features are ever
  required, revisit — but that is a new decision, not a prerequisite.
- **`agent_bots` quota customization is now vestigial** (no bot is ever created by the
  platform, and tenants cannot create bots under the SSO-only / agent-only model). It
  is left in place as inert, isolated `custom/` defense-in-depth (zero upstream-merge
  cost); a future cleanup MAY drop `custom/app/models/custom/agent_bot.rb`, the
  `custom/.../agent_bots_controller.rb` override, and the `app/models/agent_bot.rb`
  hook, and stop counting `agent_bots` in `EntitlementService`. Not done here to avoid
  changing live entitlement code without a `spec/custom` run.

## Verification (live, 2026-07-04)

Provisioned tenant → account `9`, inbox `6`:

```
account_users: user 9 role=administrator platform_managed=true
               user 10 role=agent         platform_managed=true   (AI reply identity)
webhooks:      subs=[message_created, conversation_status_changed] platform_managed=true
agent_bots:    (none)
EntitlementService usage → agents=0  webhooks=0  inboxes=1  agent_bots=0
```

A customer `message_created` drove: signature verified → enqueue → orchestrator →
`outgoing` reply posted back into the same conversation via the agent-user token. No
seat consumed, no self-loop.
