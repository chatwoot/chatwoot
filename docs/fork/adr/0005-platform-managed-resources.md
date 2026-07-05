# ADR-0005: Platform-managed resources are excluded from tenant entitlements

**Status:** Accepted (2026-07-04)
**Resolves:** the "Open item — `agent_bots` quota" left in
[ADR-0002](./0002-agentbot-canonical-ai-identity.md).

> **Identity note (ADR-0006).** This ADR was written while ADR-0002's AgentBot was
> still the planned AI identity, so it calls the AI reply resource "the system AI
> AgentBot". That resource is now the **platform-managed `role: agent` account_user**
> ([ADR-0006](./0006-ai-reply-identity-platform-managed-agent-user.md)): it is an
> `account_user`, not an `agent_bot`, so the `agents` counter (not `agent_bots`) is
> what `platform_managed: true` exempts it from. The **mechanism** below is unchanged
> and live-verified; only the identity label is superseded. With no AgentBot ever
> created, the `agent_bots` counter/guard is inert (kept as isolated defense-in-depth).

## Context

The AI reply identity is a system-managed AgentBot (ADR-0002). It is not a human
agent, so it correctly never touches the `agents` quota. But three pieces of
**platform infrastructure** are still provisioned inside each tenant account and
were being counted against tenant plan limits:

- the **system AI AgentBot** → consumed an `agent_bots` slot;
- its **account webhook** (orchestrator ingest) → consumed a `webhooks` slot;
- the platform's **automation `account_user`** (the service identity that makes
  Application-API calls) → consumed an `agents` seat.

Reserving billable plan slots for the platform's own automation is wrong: a plan
sold as "3 agents, 1 bot, 2 webhooks" should give the tenant 3 agents, 1 bot, and
2 webhooks — not 2/0/1 after the platform takes its cut. The earlier stopgap
("size plans with `agent_bots >= 1`") pushed platform accounting onto every plan
definition and was fragile.

## Decision

**Introduce a first-class `platform_managed` flag distinguishing platform
infrastructure from tenant-billable resources. Platform-managed resources are
excluded from all entitlement counts and are never blocked by tenant quotas.**

- A boolean column `platform_managed` (default `false`, `null: false`) is added to
  `agent_bots`, `webhooks`, and `account_users`
  (`db/migrate/20260704000000_add_platform_managed_to_platform_resources.rb`).
- `Custom::EntitlementService::RESOURCE_COUNTERS` counts only
  `where(platform_managed: false)` for `agents`, `agent_bots`, and `webhooks`.
- Both guard layers skip platform-managed creates: the model guard
  (`Custom::Concerns::QuotaGuard#ensure_quota_capacity`) and the controller guards
  (`check_webhooks_quota` / `check_agent_bots_quota`). Infrastructure is therefore
  never counted **and** never rejected, even when the tenant is at their cap.
- The flag is set only on **administrator-only** create paths (Application-API
  `webhooks`/`agent_bots`, guarded by `WebhookPolicy`/`AgentBotPolicy#create?`)
  and the **super-admin** Platform-API `account_users` create. In this SaaS the
  only administrator is the platform's own service user (human operators SSO in as
  `role: agent`, and native login is locked down — ADR + `SsoOnlyLogin`), so the
  flag is not tenant-settable in practice.
- **Tenant-created resources keep `platform_managed: false` and count exactly as
  before.** The change is backward-compatible: the column defaults to `false`, so
  existing rows and all tenant self-service creates are unaffected.

## Consequences

- Plans mean what they say: `agents`, `agent_bots`, and `webhooks` caps now count
  **only tenant resources**. Provisioning no longer reserves a slot for the system
  bot/webhook/service-user, and the ADR-0002 "size `agent_bots >= 1`" workaround is
  retired.
- Provisioning must set `platform_managed: true` when creating the system AgentBot,
  the account webhook, and the automation service `account_user`. Human handoff
  agents are created **without** the flag and still count toward `agents`.
- The trust boundary rests on "only the platform is an administrator." If a
  deployment ever grants a tenant the `administrator` role with API access, that
  tenant could self-exempt webhooks/bots from their cap — so keep the SSO-only
  lockdown and agent-only handoff model in force. A future hardening could gate the
  flag behind a super-admin-only context on the Application API if that assumption
  changes.
- Scope is limited to resources that are genuinely platform infrastructure
  (`agents`, `agent_bots`, `webhooks`). `teams`, `inboxes`, `labels`, etc. remain
  purely tenant-owned and are unaffected.
</content>
