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
- On the Application API (`webhooks`/`agent_bots`), the flag is honored **only when
  the acting identity is itself platform-managed** — i.e. `Current.account_user`
  is a `platform_managed` account_user (the control plane's service user). Any
  other caller (including a tenant `administrator`) has the `platform_managed` key
  **stripped from permitted params** (`Custom::Concerns::PlatformActor#platform_actor?`,
  applied in the custom `webhooks`/`agent_bots` controllers), so it can never be
  persisted `true` and never skips the quota guard. This is an *enforced* check, not
  a deployment assumption: even a tenant identity promoted to `administrator` is not
  platform-managed and so cannot self-exempt.
- The **super-admin** Platform-API `account_users` create still sets the flag
  directly. That surface requires the platform app token the control plane alone
  holds (there is no `Current.account_user` context to gate on), so it is
  platform-only by construction and needs no additional check.
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
- The trust boundary is enforced in code, not by deployment assumption: the
  Application-API exemption is keyed off the acting identity's own `platform_managed`
  flag (`PlatformActor#platform_actor?`), so granting a tenant the `administrator`
  role would **not** let them self-exempt — a tenant admin's `platform_managed: true`
  is stripped and the resource still counts. The SSO-only lockdown and agent-only
  handoff model remain the primary boundary, but they are now backed by a
  fail-closed param filter rather than relied upon alone. (Original loophole raised
  by the fork review — `platform_managed` flag abuse on `agent_bots`/`webhooks`.)
- Scope is limited to resources that are genuinely platform infrastructure
  (`agents`, `agent_bots`, `webhooks`). `teams`, `inboxes`, `labels`, etc. remain
  purely tenant-owned and are unaffected.
</content>
