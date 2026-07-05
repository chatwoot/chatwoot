# System Architecture Contract (cross-repo, authoritative)

**Audience:** engineers on **both** repositories — this Chatwoot fork and the
external meta-saas monorepo (Next.js dashboard + NestJS control plane + LangGraph
orchestrator).

**Status:** authoritative reference. Where this document and any repo's code
disagree, the disagreement is a bug; fix it to match the relevant
[ADR](./adr/README.md). This doc describes **ownership and flows across systems**;
for the fork's internal overlay mechanics see [ARCHITECTURE.md](./ARCHITECTURE.md),
and for the exact API/webhook contract see
[CHATWOOT_ENGINE_INTEGRATION.md](./CHATWOOT_ENGINE_INTEGRATION.md).

---

## 1. The five systems

```text
   ┌───────────────┐        ┌──────────────────┐        ┌───────────────────────┐
   │  Next.js      │  HTTP  │  NestJS control  │  Meta  │  Meta (WhatsApp /      │
   │  dashboard    │───────▶│  plane +         │        │  Messenger / IG)      │
   │  (tenant UI)  │        │  LangGraph       │        └───────────┬───────────┘
   └───────────────┘        │  orchestrator    │                    │ channel
                            └───────┬──────────┘                    │ (owned by Chatwoot)
                    Platform API │   │ Application API               ▼
                    (provision)  │   │ (reply, read)        ┌─────────────────┐
                                 ▼   ▼                      │    Chatwoot     │
                            ┌─────────────────┐  webhook    │    fork (this   │
                            │    Chatwoot     │────────────▶│    repo)        │
                            │    fork (this   │  (signed     └─────────────────┘
                            │    repo)        │  message_created)
                            └─────────────────┘
```

| # | System | Repo | Owns |
| - | ------ | ---- | ---- |
| 1 | **Next.js dashboard** | meta-saas | Tenant-facing UI: onboarding, billing, usage meters, AI config. The only login surface. |
| 2 | **NestJS control plane** | meta-saas | Provisioning, entitlements source-of-truth, billing, tenant isolation, webhook ingest + verification. |
| 3 | **LangGraph orchestrator** | meta-saas | The AI: runs the model, decides reply vs handoff, counts + enforces agentic-AI usage. |
| 4 | **Chatwoot fork** | **this repo** | Messaging gateway; conversation state; capacity-quota enforcement; agentic-AI limit *display*. |
| 5 | **Meta channels** | external | WhatsApp / Messenger / Instagram transport — connected **only** to Chatwoot (ADR-0001). |

---

## 2. Ownership matrix (who is authoritative for what)

| Capability | Next.js | NestJS | LangGraph | Chatwoot fork | Meta |
| --- | :-: | :-: | :-: | :-: | :-: |
| Customer ↔ business message transport | | | | | **●** (via Chatwoot) |
| Inbound message → platform (signed webhook) | | | | **● emits** | |
| Live conversation state / history | | | | **●** | |
| AI reply generation | | | **●** | | |
| Posting the reply back to the channel | | | | **● delivers** | |
| **Human-agent / team / inbox quotas** | | | | **● enforces** | |
| Agentic-AI **usage** cap: counting + enforcing | | | **●** | | |
| Agentic-AI usage cap: **display** to tenant | | | | **●** | |
| Billing, plans, entitlement source-of-truth | | **●** | | | |
| Tenant isolation / data separation | | **●** | | **●** (row-level per account) | |
| Webhook signature verification (ingest) | | **●** | | **● signs** | |
| AI usage metering / token counting | | | **●** | | |
| Authentication / login surface | **●** | **●** | | (SSO handoff only) | |
| AI reply identity (`AI_REPLY_TOKEN`) | | **● stores (encrypted)** | **● uses** | **● provisions platform-managed `role: agent` user** | |
| Provisioning (accounts, users, inboxes, AI user, webhook) | | **●** (Platform API) | | **● executes** | |

Legend: **●** = authoritative/owner. Blank = not involved. Read the columns to see
each system's surface; read the rows to see who to talk to for a capability.

**Two invariants that fall out of the matrix:**

1. **Chatwoot never stores AI rules, billing, or usage truth** — only conversation
   state and the capacity caps it enforces. (ADR-0001)
2. **The AI identity is a platform-managed `role: agent` account_user, not a human
   agent** — `platform_managed: true` excludes it from the `agents` quota. (ADR-0006,
   ADR-0005)

---

## 3. Sequence diagrams

> Rendered as Mermaid. `CW` = Chatwoot fork, `CP` = NestJS control plane,
> `LG` = LangGraph orchestrator, `UI` = Next.js dashboard.

### 3.1 Tenant onboarding + provisioning

```mermaid
sequenceDiagram
    participant Admin as Tenant admin
    participant UI as Next.js
    participant CP as NestJS control plane
    participant CW as Chatwoot fork

    Admin->>UI: Sign up / create workspace
    UI->>CP: POST /provisioning/register {tenant, adminEmail, plan}
    Note over CP: idempotent ChatwootProvisioningService
    CP->>CW: POST /platform/api/v1/accounts {name, limits:{agents,inboxes,teams,agent_bots,webhooks,...,agentic_ai}}
    CW-->>CP: 201 {id}
    CP->>CW: POST /platform/api/v1/users {name,email,password}
    CW-->>CP: 201 {id, access_token} — USER_TOKEN (service admin)
    CP->>CW: POST /platform/api/v1/accounts/{id}/account_users {user_id, role:"administrator", platform_managed:true}
    CP->>CW: POST /api/v1/accounts/{id}/inboxes {channel:{type:"api", webhook_url}}  (USER_TOKEN)
    CW-->>CP: 201 {id} — inbox
    CP->>CW: POST /platform/api/v1/users {name:"Acme AI", email, password} → AI user  (PLATFORM_TOKEN)
    CW-->>CP: 201 {id, access_token} — AI_REPLY_TOKEN, the AI identity (ADR-0006)
    CP->>CW: POST /platform/api/v1/accounts/{id}/account_users {user_id, role:"agent", platform_managed:true} — excluded from quota (ADR-0005)
    CP->>CW: add AI user to inbox(es): POST /api/v1/accounts/{id}/inbox_members {inbox_id, user_ids:[ai_user_id]}
    CP->>CW: POST /api/v1/accounts/{id}/webhooks {url, subscriptions:["message_created","conversation_status_changed"], platform_managed:true}  (USER_TOKEN)
    CW-->>CP: 201 {payload:{webhook:{secret}}} — per-tenant WEBHOOK_SECRET (ADR-0003)
    CP->>CP: store account_id, USER_TOKEN, AI_REPLY_TOKEN(enc), webhook secret(enc) — map account.id→tenant
    CP-->>UI: {tenantId, ready}
    Note over CP,CW: Degrades gracefully — if CW is down, register still succeeds, provisioning retried on next ensureAccount
```

### 3.2 Everyday AI reply loop

```mermaid
sequenceDiagram
    participant Cust as Customer (WhatsApp)
    participant CW as Chatwoot fork
    participant CP as NestJS ingest
    participant LG as LangGraph worker

    Cust->>CW: "What time do you close?"
    CW->>CP: POST /webhooks/chatwoot  (signed: X-Chatwoot-Signature/Timestamp/Delivery)
    Note over CP: verify HMAC over "{ts}.{rawBody}" with tenant secret → 401 if bad
    CP->>CP: dedupe (Delivery id AND account_id+message.id)
    CP->>CP: filter: event=message_created, message_type="incoming", private=false, status∈{open,pending}
    CP-->>CW: 200 OK (fast, <100ms) + enqueue
    CP->>LG: job {account_id, conversation_id, message}
    LG->>LG: check agentic-AI cap (STOP if over) → fetch context → model → decide
    alt reply
        LG->>CW: POST /api/v1/accounts/{id}/conversations/{cid}/messages {content, message_type:"outgoing"}  (AI_REPLY_TOKEN)
        CW->>Cust: deliver reply
        Note over CW,CP: CW echoes a message_created(outgoing) → CP drops it (fails incoming filter) — no loop
        LG->>CW: PATCH /platform/api/v1/accounts/{id} {custom_attributes:{agentic_ai_usage}}  (periodic/batched)
    else no-op (human should handle)
        LG->>LG: mark processed (successful no-op, not an error)
    end
```

### 3.3 Over-limit / AI paused

```mermaid
sequenceDiagram
    participant Cust as Customer
    participant CW as Chatwoot fork
    participant CP as NestJS ingest
    participant LG as LangGraph
    participant Admin as Tenant admin (UI)

    Cust->>CW: message
    CW->>CP: signed webhook
    CP->>LG: enqueue
    LG->>LG: agentic-AI usage >= cap  OR  AI toggled off
    Note over LG: automation.blocked — do NOT run model, spend nothing, record reason
    LG--xCW: (no outgoing reply)
    Note over CW: conversation stays open — a human can still reply by hand (never blocked)
    Admin->>CW: (optional) human opens conversation, replies manually → delivered
    Admin->>Admin: dashboard shows "AI paused — allowance used up" (banner when consumed>=allowed)
```

### 3.4 Human handoff + resume

```mermaid
sequenceDiagram
    participant Cust as Customer
    participant CW as Chatwoot fork
    participant Agent as Human agent (in Chatwoot)
    participant CP as NestJS ingest
    participant LG as LangGraph

    Note over LG: AI decides a human should handle (refund / anger / low confidence) OR agent jumps in
    Agent->>CW: opens conversation, replies (message_type outgoing, authored by human user)
    CW->>Cust: deliver human reply
    CW->>CP: message_created(outgoing) webhook
    CP->>CP: active handoff session for conversation? → yes → treat as human reply, keep AI quiet
    Cust->>CW: follow-up message (incoming)
    CW->>CP: message_created(incoming)
    CP->>CP: handoff active → AI stays quiet (do not enqueue a reply)
    Agent->>CW: resolve conversation
    CW->>CP: conversation_status_changed {status:"resolved"}
    CP->>CP: clear handoff → AI resumes for future messages
```

### 3.5 Quota enforcement (Chatwoot-owned resources)

```mermaid
sequenceDiagram
    participant CP as NestJS control plane
    participant CW as Chatwoot fork

    Note over CP,CW: Creating a team / inbox / webhook / agent_bot — capacity resources CW owns
    CP->>CW: POST /api/v1/accounts/{id}/teams {name}  (USER_TOKEN)
    alt under cap
        CW-->>CP: 201 {id}
    else at cap — controller-guarded create
        CW-->>CP: 402 {error, error_code:"quota_exceeded", resource:"teams", current, limit}
    end
    Note over CP,CW: account_users (agents) is model-guarded, not controller-guarded
    CP->>CW: POST /platform/api/v1/accounts/{id}/account_users {role:"administrator"}
    alt under agents cap
        CW-->>CP: 201
    else at cap — model-level guard
        CW-->>CP: 422 {message:"Account limit exceeded for agents (n/n)...", attributes:["base"]}
    end
    Note over CP: treat BOTH 402 and 422 "Account limit exceeded" as "upgrade needed"
    Note over CP: the AI reply user is platform_managed → excluded from the agents cap (ADR-0006/0005)
```

---

## 4. Cross-repo change protocol

- A change to any **frozen contract** (route paths, webhook event names,
  `X-Chatwoot-*` headers, existing response keys) requires a superseding ADR and a
  coordinated change in **both** repos — it is never a one-sided edit.
- Additive changes (new JSON keys, new limit keys) are allowed without an ADR but
  must be recorded in [UPSTREAM_DIFF.md](./UPSTREAM_DIFF.md) and reflected in
  [CHATWOOT_ENGINE_INTEGRATION.md](./CHATWOOT_ENGINE_INTEGRATION.md).
- When the two integration documents drift, reconcile them in
  [INTEGRATION_RECONCILIATION.md](./INTEGRATION_RECONCILIATION.md) and, if a
  decision is involved, record it as an ADR.
</content>
