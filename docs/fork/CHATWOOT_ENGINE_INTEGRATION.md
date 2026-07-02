# Chatwoot Engine — External Integration Contract

**Audience:** the external SaaS control plane + AI orchestrator (NestJS / LangGraph
repo). This is a self-contained description of everything the Chatwoot engine
(this fork) exposes and expects, so the other system can be built and verified
against it. Hand this file to that repo directly.

**Golden rule:** this fork adds **no new endpoints** and changes **no existing
Chatwoot contract**. Everything below rides on stock Chatwoot Platform/Application
APIs and webhooks. The fork only (a) enforces per-account quotas and (b) surfaces
an externally-owned "agentic AI" limit in the dashboard. Treat all route paths,
event names, headers, and JSON keys named here as frozen.

---

## 1. Systems overview

```text
                 Platform API (provisioning)          Application API (per-tenant)
Control plane  ───────────────────────────►  Chatwoot  ◄───────────────────────────  AI orchestrator
(NestJS)        create account/user/limits            engine        reply via message API   (NestJS worker)
     │                                                   │
     │         writes agentic-AI usage/limit             │  message_created webhook (signed)
     └───────────────────────────────────────────────►  └───────────────────────────────────►  orchestrator ingest
```

Three independent responsibilities:

1. **Provisioning** (control plane → Chatwoot Platform API): create tenant
   account, admin user, plan limits, webhook, and AI bot.
2. **AI reply loop** (Chatwoot → orchestrator → Chatwoot Application API):
   Chatwoot fires a signed `message_created` webhook; the orchestrator verifies,
   filters, and posts a reply back via the message-create API.
3. **Quotas** (both directions): the control plane sets caps; Chatwoot enforces
   Chatwoot-owned resources (agents, inboxes, …) and *displays* the
   externally-enforced agentic-AI limit.

---

## 2. Configuration the external system needs

| Name | What it is | Where it comes from |
| --- | --- | --- |
| `BASE_URL` | Chatwoot engine base URL, e.g. `https://app.tenant-crm.com` | deploy |
| `PLATFORM_TOKEN` | Platform App access token (super-admin scoped) | Super Admin → Platform Apps → create app → `access_token` |
| `USER_TOKEN` | A tenant admin user's `access_token` | returned when the user is created (§4.2) |
| `BOT_TOKEN` | An AgentBot's `access_token`, used to author AI replies | returned when the bot is created (§4.3) |
| `WEBHOOK_SECRET` | Per-tenant HMAC secret for verifying deliveries | you generate it and set it on the webhook (§4.3) |

Auth header for **every** call is the same: `api_access_token: <token>`.
There is no `Bearer` scheme. Which token to use:

- Platform API (`/platform/api/v1/...`) → `PLATFORM_TOKEN`
- Application API (`/api/v1/accounts/{id}/...`) → `USER_TOKEN` or `BOT_TOKEN`
  depending on the action (bot token for authoring AI replies).

> Platform APIs work only on **self-hosted** installs. This fork is self-hosted
> from Chatwoot's point of view (`DEPLOYMENT_ENV != cloud`), so they are available.

---

## 3. Authentication model (summary)

| Token | Scope | Set as | Used for |
| --- | --- | --- | --- |
| `PLATFORM_TOKEN` | installation | `api_access_token` | create/update/delete accounts, users, account_users, agent_bots |
| `USER_TOKEN` | one tenant account (as that user's role) | `api_access_token` | create webhooks, agent bots, inboxes; read limits; anything an admin can do |
| `BOT_TOKEN` | one agent bot | `api_access_token` | POST outgoing messages (AI replies), read conversation history |

---

## 4. Tenant provisioning (Platform API)

All calls send `-H "api_access_token: $PLATFORM_TOKEN" -H "Content-Type: application/json"`.

### 4.1 Create the account with plan limits

```http
POST {BASE_URL}/platform/api/v1/accounts
{
  "name": "Acme Inc",
  "limits": {
    "agents": 3, "inboxes": 2, "teams": 2, "agent_bots": 1, "webhooks": 2,
    "labels": 20, "custom_attribute_definitions": 10,
    "automation_rules": 5, "integrations": 3
  }
}
```

- Omitted limit keys → **unlimited**.
- **Unknown limit keys → HTTP 422** (schema in
  `custom/app/models/custom/account/plan_usage_and_limits.rb`). The full valid
  set is: `agents, inboxes, teams, agent_bots, webhooks, labels,
  custom_attribute_definitions, automation_rules, integrations, agentic_ai`
  (plus enterprise keys `captain_responses, captain_documents, emails`).
- Response includes the account `id`.

> **⚠️ jsonb REPLACE semantics.** `PATCH /platform/api/v1/accounts/{id}` with a
> `limits` (or `custom_attributes`) object **replaces the entire hash**, it does
> not merge. Always send the *complete* object you want stored. The control plane
> must hold the authoritative per-tenant `limits`/`custom_attributes` state.

### 4.2 Create the tenant admin

```http
POST {BASE_URL}/platform/api/v1/users
{ "name": "Admin", "email": "admin@acme.test", "password": "<generated>" }
# → response includes user id and access_token  (this is USER_TOKEN)

POST {BASE_URL}/platform/api/v1/accounts/{ACCOUNT_ID}/account_users
{ "user_id": <USER_ID>, "role": "administrator" }
```

> Adding an `account_user` consumes an **agents** quota seat (model-level guard).
> Provision `limits.agents` before adding users, or the create returns 402 (§6.3).

### 4.3 AI-loop plumbing (webhook + bot) — uses `USER_TOKEN`

```http
# Account webhook → orchestrator ingest URL (consumes one `webhooks` slot)
POST {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/webhooks
Headers: api_access_token: {USER_TOKEN}
{ "webhook": {
    "url": "https://orchestrator.example.com/ingest/{TENANT}",
    "subscriptions": ["message_created"] } }

# Agent bot to author AI replies (consumes one `agent_bots` slot)
POST {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/agent_bots
Headers: api_access_token: {USER_TOKEN}
{ "name": "AI Assistant", "outgoing_url": "" }
# → response includes the bot access_token  (this is BOT_TOKEN)
```

- Set the webhook signing secret so deliveries carry `X-Chatwoot-Signature`
  (§7.2). (Depending on the Chatwoot version the secret is auto-generated and
  returned on the webhook object, or settable — read it off the created webhook.)
- Attach the bot to the tenant's inboxes (the `agent_bot` inbox association) so
  it can act on those conversations.

### 4.4 Store per tenant in the control plane

`account_id`, `webhook_secret`, `bot_access_token` (`BOT_TOKEN`), and any
orchestrator config (LangGraph, model, etc.).

---

## 5. Agentic-AI limit contract (the fork's one extra surface)

The **agentic-AI (automated-workflow) usage limit is enforced by YOU (the NestJS
backend)**, not by Chatwoot. Chatwoot only *displays* it so the tenant sees a
warning banner. Enforcement, counting, and blocking of AI actions stay entirely
in the orchestrator.

### 5.1 What Chatwoot reads (you must write these)

Via the Platform API (`PATCH /platform/api/v1/accounts/{id}`, full-object writes
per the §4.1 caveat):

| Field | Meaning | Example |
| --- | --- | --- |
| `limits.agentic_ai` | the cap (max AI actions in the period) | `500` |
| `custom_attributes.agentic_ai_usage` | current usage count | `500` |

```http
PATCH {BASE_URL}/platform/api/v1/accounts/{ACCOUNT_ID}
Headers: api_access_token: {PLATFORM_TOKEN}
{
  "limits":            { ...all existing caps..., "agentic_ai": 500 },
  "custom_attributes": { ...all existing attrs..., "agentic_ai_usage": 500 }
}
```

### 5.2 What Chatwoot does with it

- `GET /enterprise/api/v1/accounts/{id}/limits` returns
  `"agentic_ai": { "allowed": <cap>, "consumed": <usage> }` — **only when
  `limits.agentic_ai` is set**. Accounts without a cap get an unchanged response.
- The dashboard shows a **global warning banner to admins** when
  `consumed >= allowed`. Source: `app/javascript/dashboard/fork/AgenticAiLimitBanner.vue`.
- This is **display-only**: there is no Chatwoot create-path, no 402, and no
  server-side block for `agentic_ai`. If you want AI actions actually stopped,
  the orchestrator must stop them.

### 5.3 Operational notes

- The banner refreshes when the dashboard fetches limits (on mount / navigation),
  not in real time. Usage you write shows up on the tenant's next limits fetch.
- Because writes REPLACE the jsonb (§4.1), send the full `limits` and
  `custom_attributes` objects. Prefer **periodic/batched** usage updates over a
  PATCH per AI action (full-object PATCH per action is heavy and race-prone).

---

## 6. Quotas for Chatwoot-owned resources

### 6.1 Setting caps

Via `limits` on account create/update (§4.1). Enforcement picks up new caps
immediately.

### 6.2 Reading usage

```http
GET {BASE_URL}/enterprise/api/v1/accounts/{ACCOUNT_ID}/limits
Headers: api_access_token: {USER_TOKEN}
```

Returns every resource as `{ "allowed": <int|null>, "consumed": <int> }`;
`allowed: null` means unlimited. This is what the dashboard quota UI reads.

### 6.3 Denial contract (402)

Any create that exceeds a Chatwoot-owned cap returns:

```json
HTTP 402 Payment Required
{
  "error": "Account limit exceeded for teams (2/2). Upgrade your plan to add more.",
  "error_code": "quota_exceeded",
  "resource": "teams",
  "current": 2,
  "limit": 2
}
```
`error_code` is always `quota_exceeded`. `resource/current/limit` are additive
machine-readable fields. This fires on API and UI create paths, including
bypass paths (channel onboarding, OAuth-created integration hooks, agent bots).
The control plane should surface `error` to the tenant and treat 402 as "upgrade
needed."

---

## 7. AI reply loop (Chatwoot → orchestrator → Chatwoot)

### 7.1 Sequence

```text
Contact sends message
  → Chatwoot fires account webhook `message_created` (signed, to your ingest URL)
    → Orchestrator: verify signature → dedupe → filter → 200 OK fast, enqueue
      → Worker: fetch context → LangGraph → decide reply | no-op
        → POST message-create API (BOT_TOKEN) → Chatwoot delivers to the contact
```

### 7.2 Delivery headers + signature (verify EXACTLY this)

On every POST to your ingest URL, when a secret is configured:

| Header | Value |
| --- | --- |
| `X-Chatwoot-Delivery` | unique delivery id (idempotency key) |
| `X-Chatwoot-Timestamp` | unix seconds, as a string |
| `X-Chatwoot-Signature` | `sha256=` + hex `HMAC_SHA256(secret, "{timestamp}.{raw_body}")` |

Recipe (from `lib/webhooks/trigger.rb`): the signed string is
`"{X-Chatwoot-Timestamp}.{raw_request_body}"`, HMAC-SHA256 with the per-webhook
secret, hex-encoded, prefixed with `sha256=`.

```ts
import { createHmac, timingSafeEqual } from 'crypto';

// rawBody MUST be the exact bytes received, before any JSON parsing/re-serialize.
function verifyChatwootWebhook(rawBody: string, headers: Record<string,string>, secret: string): boolean {
  const ts  = headers['x-chatwoot-timestamp'];
  const sig = headers['x-chatwoot-signature'];
  if (!ts || !sig) return false;                                   // 1. reject if missing → 401
  if (Math.abs(Date.now() / 1000 - Number(ts)) > 300) return false; // 4. replay window: 300s
  const expected = 'sha256=' + createHmac('sha256', secret)
    .update(`${ts}.${rawBody}`).digest('hex');                     // 2. HMAC over "{ts}.{rawBody}"
  const a = Buffer.from(sig), b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);           // 3. constant-time compare
}
```

In NestJS, capture the **raw body** (e.g. `rawBody` via `bodyParser.json({ verify })`
or `express.raw`) — verifying against `JSON.stringify(parsedBody)` will fail
because key order/whitespace differ.

### 7.3 `message_created` payload

Top level includes `event: "message_created"` plus the message fields:

```json
{
  "event": "message_created",
  "id": 123,
  "content": "hello",
  "message_type": "incoming",
  "content_type": "text",
  "content_attributes": {},
  "created_at": "2026-07-03T10:00:00.000Z",
  "private": false,
  "source_id": null,
  "sender": { "id": 45, "name": "Jane", "type": "contact", "...": "..." },
  "conversation": { "id": 67, "status": "open", "...": "..." },
  "inbox": { "id": 8, "name": "Website", "...": "..." },
  "account": { "id": 3, "name": "Acme Inc" }
}
```

Fields you must key on:

- `event` — `"message_created"` (also `"message_updated"`,
  `"conversation_status_changed"` if you subscribe to them).
- `message_type` — `"incoming" | "outgoing" | "activity" | "template"`.
- `private` — `true` for internal agent notes.
- `sender.type` — `"contact"` (end user) vs `"user"` / `"agent_bot"`.
- `conversation.status` — `"open" | "pending" | "resolved" | "snoozed"`.
- `account.id` — tenant id. **Only trust it after the signature verifies against
  that tenant's secret** — safest is a per-tenant ingest path (`/ingest/{tenant}`).

### 7.4 Loop-prevention filter (run BEFORE enqueue)

Process only if **all** hold; otherwise ack `2xx` and drop (never 4xx/5xx an event
you merely ignore — that triggers Chatwoot's retry machinery):

| Check | Condition |
| --- | --- |
| message event | `event == "message_created"` |
| inbound | `message_type == "incoming"` |
| not a note | `private == false` |
| from a contact | `sender.type == "contact"` |
| not the bot itself | `sender.id != <provisioned bot id>` |
| conversation eligible | `conversation.status ∈ {open, pending}`; skip if a human took over (your handoff rule) |

The structural loop guarantee: your reply is `outgoing`, so the
`message_created` it generates fails `message_type == "incoming"`.

### 7.5 Idempotency

Chatwoot retries on delivery failure. Dedupe on `X-Chatwoot-Delivery`
**and** on `(account_id, message.id)` (a different delivery can carry the same
message). Suggested store: Redis `SET key 1 NX EX 86400`; if present → `200 OK`,
no work. Mark processed **after** the reply posts (or a definitive no-op), and
make the reply itself safe by checking for an existing bot reply to that
`message.id` first.

### 7.6 Reply path

```http
POST {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/conversations/{CONVERSATION_ID}/messages
Headers: api_access_token: {BOT_TOKEN}
{ "content": "<reply text>", "message_type": "outgoing" }
```

### 7.7 Context (conversation history for the prompt)

```http
GET {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/conversations/{CONVERSATION_ID}/messages
Headers: api_access_token: {BOT_TOKEN}
```

### 7.8 Operational rules

- Ingest = verify + dedupe + filter + enqueue only; target < 100 ms. Model calls
  run in workers.
- Worker outcomes: `reply`, `no_op` (both mark processed), `retryable_error`
  (bounded retry + backoff → dead-letter + alert). "A human should handle this"
  is a **successful** no-op, not a failure.
- Log per event: delivery id, account id, message id, decision, latency.

---

## 8. Frozen contracts — do NOT rely on anything else / do NOT expect changes

- Route paths, HTTP methods, and the `api_access_token` header are fixed.
- Webhook event names (`message_created`, …) and the `X-Chatwoot-Timestamp` /
  `X-Chatwoot-Signature` / `X-Chatwoot-Delivery` header names and formats are
  fixed. Do not rebrand or rename them (the `X-Chatwoot-*` names are part of the
  contract even though the product is white-labeled).
- Existing response keys are never removed/renamed; the fork only **adds** keys
  (`agentic_ai` in limits; `error_code/resource/current/limit` in 402s).

---

## 9. Branding (informational)

The product is white-labeled via Chatwoot installation config
(`INSTALLATION_NAME`, `BRAND_NAME`, logos, URLs). This does **not** affect any
API/webhook contract — payloads, headers, and routes keep the `Chatwoot`/
`X-Chatwoot-*` identifiers. If the orchestrator composes user-facing copy, read
the tenant/brand name from your own config, not from these APIs.

---

## 10. End-to-end worked example (happy path)

```text
1. POST /platform/api/v1/accounts            {name, limits:{agents,...,agentic_ai}}  → account_id
2. POST /platform/api/v1/users               {name,email,password}                    → USER_TOKEN
3. POST /platform/api/v1/accounts/{id}/account_users {user_id, role:"administrator"}
4. POST /api/v1/accounts/{id}/webhooks       {webhook:{url, subscriptions:["message_created"]}}  (USER_TOKEN)  → note secret
5. POST /api/v1/accounts/{id}/agent_bots     {name:"AI Assistant"}                    (USER_TOKEN)  → BOT_TOKEN
6. attach bot to inbox(es)
   … runtime …
7. contact messages → Chatwoot POSTs message_created (signed) → orchestrator verify+filter → 200
8. worker → LangGraph → POST /api/v1/accounts/{id}/conversations/{cid}/messages {content, message_type:"outgoing"} (BOT_TOKEN)
9. periodically: PATCH /platform/api/v1/accounts/{id} {limits:{...,agentic_ai}, custom_attributes:{...,agentic_ai_usage}}
   → dashboard banner warns the tenant when consumed >= allowed
```

## 11. Endpoint quick reference

| Method & path | Token | Purpose |
| --- | --- | --- |
| `POST /platform/api/v1/accounts` | PLATFORM | create tenant + limits |
| `PATCH /platform/api/v1/accounts/{id}` | PLATFORM | update limits / custom_attributes (full-object) |
| `POST /platform/api/v1/users` | PLATFORM | create user → USER_TOKEN |
| `POST /platform/api/v1/accounts/{id}/account_users` | PLATFORM | attach user (uses an agents seat) |
| `POST /api/v1/accounts/{id}/webhooks` | USER | subscribe orchestrator to `message_created` |
| `POST /api/v1/accounts/{id}/agent_bots` | USER | create AI bot → BOT_TOKEN |
| `GET  /enterprise/api/v1/accounts/{id}/limits` | USER | read `{allowed,consumed}` per resource incl. `agentic_ai` |
| `POST /api/v1/accounts/{id}/conversations/{cid}/messages` | BOT | post AI reply (`message_type:"outgoing"`) |
| `GET  /api/v1/accounts/{id}/conversations/{cid}/messages` | BOT | fetch history for the prompt |

*All paths are relative to `BASE_URL`. All auth via `api_access_token` header.*
