# ADR-0001: Chatwoot is the single messaging gateway

**Status:** Accepted (2026-07-04)
**Relates to:** meta-saas ADR-0015 (automation control plane), which supersedes
meta-saas ADR-0014 (Meta-direct).

## Context

Customers reach a business over WhatsApp / Messenger / Instagram. Two topologies
were considered:

1. **Meta-direct** (meta-saas ADR-0014): the platform connects to the Meta APIs
   itself and uses Chatwoot only as an agent console.
2. **Chatwoot-as-gateway** (this ADR): Chatwoot owns the channel connections and
   is the sole inbound **and** outbound path; the platform automates on top of it.

Running two independent connections to the same Meta channel causes duplicate
delivery, split conversation state, and two places that can each rate-limit or
desync. The platform's value is automation + governance, not owning transport.

## Decision

**Chatwoot is the single customer-messaging gateway, inbound and outbound.** The
external platform never calls Meta directly. Concretely:

- Every inbound customer message enters through Chatwoot and is delivered to the
  platform as a **signed `message_created` webhook**.
- Every outbound reply (AI or human) is posted **back into the same Chatwoot
  conversation** via the Application API; Chatwoot delivers it to the channel.
- Chatwoot holds the **live conversation state**; the platform holds AI usage,
  billing, entitlements, and tenant isolation. Neither stores the other's.

The platform drives Chatwoot **backend-to-backend** through existing public
contracts only: the Platform API (provisioning) and the Application API
(per-tenant reads/writes). No fork-specific endpoints are added
(`docs/fork/UPSTREAM_DIFF.md`).

## Consequences

- The fork's job is narrow and upgrade-safe: enforce per-tenant quotas on
  Chatwoot-owned resources and surface an externally-owned agentic-AI limit
  (ADR-0004). All AI lives outside this repo.
- The webhook contract (`lib/webhooks/trigger.rb`) and the message-create API are
  **frozen public contracts** — extend additively only.
- `META_TRANSPORT_ENABLED` remains **dormant/`false`** in the platform; the
  meta-direct code path is retained but not the supported topology.
- A single egress IP posting all tenants' replies shares Chatwoot's
  `RACK_ATTACK_LIMIT` (3,000 req/min/IP) — the platform must back off on `429`
  (see `CHATWOOT_ENGINE_INTEGRATION.md` §7.9).
</content>
