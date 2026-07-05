# ADR-0002: A system-managed AgentBot is the canonical AI reply identity

**Status:** ⛔ Superseded by [ADR-0006](./0006-ai-reply-identity-platform-managed-agent-user.md) (2026-07-04)
**Resolves:** the reply-identity divergence between
`CHATWOOT_ENGINE_INTEGRATION.md` §4.3 (AgentBot) and the meta-saas integration
guide (plain agent user).

> **Superseded — retained for history.** The AgentBot was never implemented, and
> [ADR-0005](./0005-platform-managed-resources.md)'s `platform_managed` flag removed
> its only justification (avoiding a burned `agents` seat): stamping the plain
> `role: agent` AI user `platform_managed: true` makes it quota-clean without a bot
> (verified live, `agents` usage `= 0`). The canonical AI reply identity is now the
> **platform-managed `role: agent` account_user** — see **ADR-0006**. The decision
> and context below are kept as the record of why the AgentBot path was considered.

## Context

The AI needs a Chatwoot identity to author outgoing replies. Two options exist,
both valid against stock Chatwoot APIs:

1. **Plain agent user** — a Platform user with `role: agent`; the AI posts as that
   user's `access_token`.
2. **AgentBot** — a Platform-created `AgentBot` with its own `access_token`
   (`BOT_TOKEN`), attached to the tenant's inboxes.

The two integration documents disagreed: the Chatwoot-side contract recommended an
AgentBot; the meta-saas guide had been built around a plain agent user. They must
converge on one, because provisioning and quota accounting differ.

Decisive fact (`custom/app/services/custom/entitlement_service.rb`):

- `agents: account.account_users.count` — a plain agent user **consumes a human
  `agents` seat**.
- `agent_bots: account.agent_bots.count` — an AgentBot is counted separately and
  **never touches the `agents` cap**.

The AI identity is infrastructure, not a human seat a tenant bought. Letting it
consume a human `agents` seat corrupts the entitlement the tenant is billed for.

## Decision

**The canonical AI reply identity is a single system-managed AgentBot per tenant.**

- It is **auto-provisioned** during tenant onboarding via the Platform API
  (`POST /platform/api/v1/agent_bots` or the account-scoped
  `POST /api/v1/accounts/{id}/agent_bots`), attached to the tenant's inbox(es).
- Its `BOT_TOKEN` is stored **encrypted** on the platform side and used
  **exclusively** by the NestJS/LangGraph automation layer to author `outgoing`
  replies. It is never exposed to tenant admins or human agents.
- It is treated as **platform infrastructure**, not a tenant-managed or
  independently billable resource.
- **It does not count toward the human `agents` quota, nor toward `teams` or
  `inboxes`.** Human agents, teams, and inboxes remain governed by plan
  entitlements; the system AI identity is a distinct concept.

The meta-saas side changes to provision an AgentBot (and stop creating a
`role: agent` service user for AI replies). The service **admin** user
(`role: administrator`, used for provisioning Application-API calls) is unchanged.

## Consequences

- **Human `agents` quota stays clean** — verified structurally: an AgentBot is not
  an `account_user`, so it is invisible to the `agents` counter. No code change is
  needed for this property; it holds today.
- **The `agent_bots` quota — RESOLVED by [ADR-0005](./0005-platform-managed-resources.md).**
  The system AgentBot (and the account webhook, and the automation service
  `account_user`) are marked `platform_managed: true` and excluded from
  entitlement counts entirely — they never consume a tenant plan slot and are never
  blocked by the tenant's cap. Provisioning sets the flag; it does **not** reserve
  a billable slot.
- The structural loop-prevention guarantee is unchanged: the bot's replies are
  `outgoing`, so they fail the `message_type == "incoming"` ingest filter — the
  bot never answers itself (`CHATWOOT_ENGINE_INTEGRATION.md` §7.4).
- Documentation must make the **human-agent vs system-AI-identity** distinction
  explicit everywhere quotas are described.
</content>
