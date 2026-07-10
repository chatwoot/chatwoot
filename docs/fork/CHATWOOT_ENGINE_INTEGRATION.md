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

## 0. How to use this file (read first — you are the external repo)

This document is a **read-only reference contract** for the Chatwoot engine your
monorepo integrates with. Build against it exactly; do not edit it here. If you
find a genuine mismatch between this file and the engine's behavior, the fix
belongs in the engine repo (`docs/fork/`), not in your copy.

**Where each section maps onto your monorepo:**

| Sections | Build in |
| --- | --- |
| §4, §5, §6, §11 — provisioning, agentic-AI cap, quota reads, endpoint list | **NestJS control-plane** module |
| §7 + §7.9 — webhook verify, filter, idempotency, reply, limits | **NestJS + LangGraph** ingest/worker |
| §4.5–4.6 — SSO login handoff + lockdown config | your **Next.js ↔ NestJS** auth layer |

**Fill in these deploy-specific blanks before you start** (only the operator of
the Chatwoot deploy knows them):

- `BASE_URL` — the Chatwoot engine URL, and `PLATFORM_TOKEN` — from Super Admin →
  Platform Apps (§2).
- Whether you enable `ENABLE_SSO_ONLY_LOGIN` / `EXTERNAL_LOGIN_URL` — the auth
  lockdown is **off by default** (§4.6). Local dev: `EXTERNAL_LOGIN_URL` points at
  your Next.js login, e.g. `http://localhost:3002/login`.
- The actual `client_max_body_size` and `ATTACHMENT_SIZE` on the target deploy if
  you will send large attachments (§7.9 pins the *reference* values, which a real
  deploy may override).

**Status / what to watch on first run:** the engine side of this contract is
**spec-verified (83 tests green) but not yet run live end-to-end**. The two places
first-integration bugs usually hide:

1. **Raw-body signature check (§7.2)** — HMAC the *exact received bytes*, never a
   re-serialized `JSON.stringify(parsed)` (key order/whitespace will differ and
   every verification will fail).
2. **Quota denials have two shapes (§6.3)** — controller creates return the
   structured `402`; model-level paths (e.g. `account_users`) return `422`. Handle
   both as "upgrade needed".

**Frozen contract:** route paths, webhook event names, `X-Chatwoot-*` headers, and
existing JSON keys never change — extend only additively (§8).

**Companion docs (authoritative for both repos):**
[SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md) (ownership matrix + sequence
diagrams), [INTEGRATION_RECONCILIATION.md](./INTEGRATION_RECONCILIATION.md)
(divergence report + local runbook), and the [ADRs](./adr/README.md) that record
the decisions this contract implements.

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
| `AI_REPLY_TOKEN` | The **platform-managed `role: agent` AI user's** `access_token`, used to author AI replies (ADR-0006) | returned when the AI user is created (§4.3) |
| `WEBHOOK_SECRET` | Per-tenant HMAC secret for verifying deliveries | you generate it and set it on the webhook (§4.3) |

Auth header for **every** call is the same: `api_access_token: <token>`.
There is no `Bearer` scheme. Which token to use:

- Platform API (`/platform/api/v1/...`) → `PLATFORM_TOKEN`
- Application API (`/api/v1/accounts/{id}/...`) → `USER_TOKEN` or `AI_REPLY_TOKEN`
  depending on the action (the AI user's token for authoring AI replies).

> Platform APIs work only on **self-hosted** installs. This fork is self-hosted
> from Chatwoot's point of view (`DEPLOYMENT_ENV != cloud`), so they are available.

---

## 3. Authentication model (summary)

| Token | Scope | Set as | Used for |
| --- | --- | --- | --- |
| `PLATFORM_TOKEN` | installation | `api_access_token` | create/update/delete accounts, users, account_users (incl. the platform-managed AI user) |
| `USER_TOKEN` | one tenant account (as that user's role) | `api_access_token` | create webhooks, inboxes; read limits; anything an admin can do |
| `AI_REPLY_TOKEN` | the platform-managed `role: agent` AI user | `api_access_token` | POST outgoing messages (AI replies), read conversation history |

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

> **⚠️ jsonb write semantics.** `PATCH /platform/api/v1/accounts/{id}`:
>
> - **`limits` REPLACES the entire hash** — always send the *complete* cap set
>   you want stored. The control plane owns every limit key, so full-object is
>   both safe and required here.
> - **`custom_attributes` is a MERGE-PATCH** (RFC 7386-style; fork override, see
>   `custom/app/controllers/custom/platform/api/v1/accounts_controller.rb`):
>   keys you send overwrite, keys you omit survive, an explicit `null` deletes a
>   key. This is deliberate — Chatwoot writes its OWN account attributes
>   (`marked_for_deletion_at`, billing/plan keys) that the control plane cannot
>   know or safely echo back, so a sparse write like
>   `{ "custom_attributes": { "agentic_ai_usage": 500 } }` must never wipe them.
>   (Under stock upstream semantics it would replace the whole hash.)

### 4.2 Create the tenant admin

```http
POST {BASE_URL}/platform/api/v1/users
{ "name": "Admin", "email": "admin@acme.test", "password": "<generated>" }
# → response includes user id and access_token  (this is USER_TOKEN)

POST {BASE_URL}/platform/api/v1/accounts/{ACCOUNT_ID}/account_users
{ "user_id": <USER_ID>, "role": "administrator" }
```

> Adding an `account_user` consumes an **agents** quota seat, enforced at the
> **model level** (not a controller guard). Provision `limits.agents` before
> adding users. Over the cap, this endpoint does **not** return the structured
> 402 — it raises a validation error and returns **HTTP 422** (§6.3, "model-level
> paths"):
>
> ```json
> HTTP 422 Unprocessable Entity
> { "message": "Account limit exceeded for agents (1/1). Upgrade your plan to add more.",
>   "attributes": ["base"] }
> ```
>
> **Platform automation service user (ADR-0005).** If this administrator is the
> platform's own service identity (the one whose `USER_TOKEN` drives provisioning
> and Application-API calls) rather than a human, create it with
> `{ "user_id": <ID>, "role": "administrator", "platform_managed": true }`. A
> platform-managed `account_user` is excluded from the `agents` count and never
> blocks on the cap. **Human** operators (handoff agents, §4.14) are created
> **without** the flag and count toward `limits.agents` as normal.

### 4.3 AI-loop plumbing (webhook + AI reply user)

```http
# Account webhook → orchestrator ingest URL (platform-managed: consumes NO slot)
# Application API, uses USER_TOKEN.
POST {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/webhooks
Headers: api_access_token: {USER_TOKEN}
{ "webhook": {
    "url": "https://orchestrator.example.com/ingest/{TENANT}",
    "subscriptions": ["message_created", "conversation_status_changed"],
    "platform_managed": true } }

# AI reply identity: a platform-managed role:agent user (ADR-0006) — consumes NO slot.
# Platform API, uses PLATFORM_TOKEN. Two calls: create the user, then associate it.
POST {BASE_URL}/platform/api/v1/users
Headers: api_access_token: {PLATFORM_TOKEN}
{ "name": "Acme AI", "email": "ai-agent-{TENANT}@handoff.local", "password": "<random>" }
# → response includes the user access_token  (this is AI_REPLY_TOKEN)

POST {BASE_URL}/platform/api/v1/accounts/{ACCOUNT_ID}/account_users
Headers: api_access_token: {PLATFORM_TOKEN}
{ "user_id": <ai_user_id>, "role": "agent", "platform_managed": true }
```

> **⚠️ Valid subscription events only.** `subscriptions` must be a subset of
> `Webhook::ALLOWED_WEBHOOK_EVENTS` (`app/models/webhook.rb`) or the create fails
> **422** and no webhook exists. In particular **`conversation_resolved` is NOT a
> webhook event** (it is a reporting event only) — do not subscribe to it.
> Subscribe to **`conversation_status_changed`** and detect resolution from its
> `status == "resolved"` payload. Minimum set for the AI loop:
> `["message_created", "conversation_status_changed"]` (ADR-0003).
>
> **The AI reply identity is a platform-managed `role: agent` account_user
> (ADR-0006).** It is platform infrastructure, not a human seat. Marking it
> `platform_managed: true` excludes it from the tenant's **`agents`** quota, so it
> consumes **no** plan slot even though it is an `account_user`. Keep
> `AI_REPLY_TOKEN` encrypted and used only by the orchestrator. (ADR-0002 originally
> proposed an `AgentBot` for this; it was never built and `platform_managed` made it
> unnecessary — an AgentBot is not required to keep the `agents` quota clean.)
>
> **Mark platform infrastructure with `platform_managed: true` (ADR-0005).** Send
> `platform_managed: true` on the **AI reply account_user** and the **account
> webhook** (both create bodies above), and on the **automation service admin user**
> (§4.2). Platform-managed resources are excluded from `agents` / `webhooks` counts
> entirely — they consume **no** tenant plan slot and are never blocked by the
> tenant's cap. Tenant-created resources omit the flag (default `false`) and count
> normally. This retires the earlier "provision `agent_bots >= 1`" workaround. The
> flag is only honored on the administrator-only / super-admin create paths.

- The webhook signing secret is **auto-generated** on create (`has_secure_token`)
  and is **not settable** via the API (`webhook_params` permits only
  `inbox_id, name, url, subscriptions, platform_managed`). **Read it from the
  create response** and
  store it as this tenant's `WEBHOOK_SECRET`; every delivery is then signed
  (`X-Chatwoot-Signature`, §7.2). If you don't capture it, you cannot verify
  deliveries. It is not rotatable through the public API (re-create the webhook to
  get a new one).
- The webhook create response is **wrapped** — the secret is at
  `payload.webhook.secret`:
  ```json
  { "payload": { "webhook": {
      "id": 12, "name": null, "url": "https://orchestrator.example.com/ingest/acme",
      "account_id": 3, "subscriptions": ["message_created"],
      "secret": "AbC123…", "inbox": null } } }
  ```
- Add the AI reply user to the tenant's inbox(es) as an **inbox member** (Application
  API `POST /api/v1/accounts/{id}/inbox_members {inbox_id, user_ids:[<ai_user_id>]}`)
  so its reply POSTs to those conversations are authorized (a `role: agent` user can
  only act in inboxes it belongs to).

### 4.4 Store per tenant in the control plane

`account_id`, `webhook_secret`, `ai_reply_access_token` (`AI_REPLY_TOKEN`), and any
orchestrator config (LangGraph, model, etc.). Also store each tenant user's
Chatwoot `user_id` (from §4.2) — you need it for the SSO login below.

### 4.5 Logging a user into Chatwoot (SSO handoff — no Chatwoot login form)

Users authenticate in **your** stack (Next.js / NestJS); they must never see
Chatwoot's own login form. To drop an already-authenticated user into their
Chatwoot dashboard, mint a one-time SSO link and redirect the browser to it:

```http
GET {BASE_URL}/platform/api/v1/users/{USER_ID}/login
Headers: api_access_token: {PLATFORM_TOKEN}
→ 200 { "url": "{BASE_URL}/app/login?email=<enc>&sso_auth_token=<token>" }
```

Then `302` the user's browser to that `url`. Chatwoot consumes the token, signs
the user in, and lands them on the dashboard — the login page shows only a
spinner during the exchange, never a form.

- Flow: user logs in on your frontend → NestJS looks up the Chatwoot `user_id`
  → `GET /platform/api/v1/users/{id}/login` → redirect the browser to `url`.
- The `sso_auth_token` is **single-use** and **expires in 5 minutes**. Mint a
  fresh one per login; never cache it.
- Disable Chatwoot self-service signup so your stack is the only entry point:
  set installation config `ENABLE_ACCOUNT_SIGNUP=false` (also hides the signup
  link on Chatwoot's login page).
- On Chatwoot **session expiry** the dashboard bounces to `/app/login`. If the
  fork's "external login redirect" is enabled, that bare page redirects to your
  login URL so users re-authenticate in your stack and get a fresh SSO link;
  otherwise they would see Chatwoot's form.

### 4.6 Locking down native Chatwoot auth (required config)

To guarantee the only way in is your stack, set these on the Chatwoot deploy
(ENV / installation config). All are enforced server-side — not just UI:

| Config | Value | Effect |
| --- | --- | --- |
| `ENABLE_SSO_ONLY_LOGIN` | `true` | **Fork:** the master lock. Rejects **every** native login server-side — password + MFA-token (session controller → `401 { "error_code": "sso_only_login" }`) **and Google OAuth + SAML** (blocked at `omniauth_success` before any token is minted → redirect to `/app/login?error=sso-only-login`). Only the Platform SSO token — mintable solely with `PLATFORM_TOKEN` — can create a session. A known password, a Google account, or a SAML assertion all fail with this one flag; you do **not** have to also disable the OAuth/SAML flags to be safe. |
| `EXTERNAL_LOGIN_URL` | your Next.js login URL | **Fork:** bare/expired visits to Chatwoot's `/app/login` redirect here instead of showing a form. |
| `ENABLE_ACCOUNT_SIGNUP` | `false` (default) | Public account signup (`POST /api/v1/accounts`) returns 404. |
| `ENABLE_GOOGLE_OAUTH_LOGIN` | `false` | *Defense-in-depth / cosmetic.* With `ENABLE_SSO_ONLY_LOGIN` on, OAuth is already refused server-side; disabling this (or not setting `GOOGLE_OAUTH_CLIENT_ID`) just hides the button. |
| `ENABLE_SAML_SSO_LOGIN` | `false` | *Defense-in-depth / cosmetic.* Same as above for SAML — the master lock already blocks it server-side. |

- **Super admin is unaffected** — it uses a separate Devise scope
  (`devise_for :super_admins` at `/super_admin`), so the operator always reaches
  the Super Admin console even with `ENABLE_SSO_ONLY_LOGIN` on.
- With `ENABLE_SSO_ONLY_LOGIN` **off** (default) native login works normally —
  the lockdown is inert until you opt in, so dev/tests are unaffected.

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
  "custom_attributes": { "agentic_ai_usage": 500 }
}
```

(`limits` must be the complete cap set — it replaces; `custom_attributes` may be
sparse — it merge-patches. §4.1.)

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
- Send the full `limits` object (it replaces — §4.1) but only the
  `custom_attributes` keys you own (`agentic_ai_usage`) — the merge-patch keeps
  the rest intact. Prefer **periodic/batched** usage updates over a PATCH per
  AI action.

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

### 6.3 Denial contract — two shapes depending on the path

The cap is always enforced (creation is blocked), but the **response shape
depends on where the guard sits**. Handle both.

**(a) Controller-guarded create endpoints → structured `402`.** These are the
per-tenant Application-API creates you call directly (`webhooks`, `agent_bots`,
`teams`, `labels`, `custom_attribute_definitions`, `automation_rules` incl.
`clone`, `integrations/hooks`):

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
`error_code` is always `quota_exceeded`; `resource/current/limit` are additive
machine-readable fields.

**(b) Model-level guarded paths → `422` (`RecordInvalid`).** The "safety net"
guard that catches paths without a controller check — **`account_users`
(agents)**, channel-onboarding-created inboxes, and OAuth-created integration
hooks (Slack/Shopify/Notion) — surfaces the same limit as a validation error:

```json
HTTP 422 Unprocessable Entity
{
  "message": "Account limit exceeded for agents (1/1). Upgrade your plan to add more.",
  "attributes": ["base"]
}
```
There is **no** `error_code/resource/current/limit` here — parse the human string
if you need the numbers, or (better) pre-check usage via §6.2 before creating.

**For the control plane:** the only over-cap path you hit in normal provisioning
is `account_users` → treat **both** `402` and `422` with an
`"Account limit exceeded"` message as "upgrade needed", and surface the message
to the tenant. Provisioning limits *before* creating resources avoids both.

---

## 7. AI reply loop (Chatwoot → orchestrator → Chatwoot)

### 7.1 Sequence

```text
Contact sends message
  → Chatwoot fires account webhook `message_created` (signed, to your ingest URL)
    → Orchestrator: verify signature → dedupe → filter → 200 OK fast, enqueue
      → Worker: fetch context → LangGraph → decide reply | no-op
        → POST message-create API (AI_REPLY_TOKEN) → Chatwoot delivers to the contact
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
  "sender": { "id": 45, "name": "Jane", "email": "jane@acme.test" },
  "conversation": { "id": 67, "status": "open", "...": "..." },
  "inbox": { "id": 8, "name": "Website", "...": "..." },
  "account": { "id": 3, "name": "Acme Inc" }
}
```

Fields you must key on:

- `event` — `"message_created"` (also `"message_updated"`,
  `"conversation_status_changed"` if you subscribe to them).
- `message_type` — the string `"incoming" | "outgoing" | "activity" | "template"`
  (sent as a string, not an integer). **This is your primary discriminator.**
- `private` — `true` for internal agent notes.
- `sender` — ⚠️ **contact senders carry no `type` field** (just `id`, `name`,
  `email`, `phone_number`, …). Only *agent* (User) senders include
  `"type": "user"`. So **do not test `sender.type == "contact"`** — it is never
  present. An `incoming` message is by construction authored by a contact; use
  `message_type` to tell customer messages from agent/bot messages.
- `conversation.status` — the string `"open" | "pending" | "resolved" | "snoozed"`.
- `account.id` — tenant id. **Only trust it after the signature verifies against
  that tenant's secret** — safest is a per-tenant ingest path (`/ingest/{tenant}`).

### 7.4 Loop-prevention filter (run BEFORE enqueue)

Process only if **all** hold; otherwise ack `2xx` and drop (never 4xx/5xx an event
you merely ignore — that triggers Chatwoot's retry machinery):

| Check | Condition |
| --- | --- |
| message event | `event == "message_created"` |
| inbound (**primary guard**) | `message_type == "incoming"` — excludes agent replies, the AI user's replies, templates, and activities in one check |
| not a note | `private == false` |
| not agent-authored (optional, defense-in-depth) | `sender.type != "user"` — note contacts have no `type` at all, so **don't** test `== "contact"` |
| conversation eligible | `conversation.status ∈ {open, pending}`; skip if a human took over (your handoff rule) |

The structural loop guarantee: your reply is `outgoing`, so the
`message_created` it generates fails `message_type == "incoming"` — that single
check is what prevents the AI from answering itself. There is no need to match
the AI user's own sender id (its messages are already excluded as `outgoing`).

### 7.5 Idempotency

Chatwoot retries on delivery failure. Dedupe on `X-Chatwoot-Delivery`
**and** on `(account_id, message.id)` (a different delivery can carry the same
message). Suggested store: Redis `SET key 1 NX EX 86400`; if present → `200 OK`,
no work. Mark processed **after** the reply posts (or a definitive no-op), and
make the reply itself safe by checking for an existing AI reply to that
`message.id` first.

### 7.6 Reply path

```http
POST {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/conversations/{CONVERSATION_ID}/messages
Headers: api_access_token: {AI_REPLY_TOKEN}
{ "content": "<reply text>", "message_type": "outgoing" }
```

### 7.7 Context (conversation history for the prompt)

```http
GET {BASE_URL}/api/v1/accounts/{ACCOUNT_ID}/conversations/{CONVERSATION_ID}/messages
Headers: api_access_token: {AI_REPLY_TOKEN}
```

### 7.8 Operational rules

- Ingest = verify + dedupe + filter + enqueue only; target < 100 ms. Model calls
  run in workers.
- Worker outcomes: `reply`, `no_op` (both mark processed), `retryable_error`
  (bounded retry + backoff → dead-letter + alert). "A human should handle this"
  is a **successful** no-op, not a failure.
- Log per event: delivery id, account id, message id, decision, latency.

### 7.9 Payload limits, validation & rate limits — respect these; some are YOURS to enforce

Chatwoot validates what hits its own API. It does **not** constrain your model,
your queue, or the agentic-AI cap. Split the responsibility as follows.

**(A) Limits Chatwoot enforces on the reply you POST (§7.6) — respect + handle:**

| Limit | Value | If you exceed it |
| --- | --- | --- |
| `content` length | **≤ 150,000 characters** | `422 Unprocessable Entity` (message not created) |
| attachments per message | **≤ 15** | `422` |
| attachment file size | **≤ 40 MB** each (deploy-configurable via `ATTACHMENT_SIZE`) | `422` |
| `content_type` / `message_type` | must be valid; reply uses `message_type: "outgoing"` | `422` |
| requests per IP | **3,000 / minute / IP** (global Rack::Attack `RACK_ATTACK_LIMIT`) | `429 Too Many Requests` |

→ **Truncate or split** AI output to ≤ 150k chars *before* POSTing. **Back off and
retry** on `429` (respect `Retry-After` if present); the throttle is per **egress
IP**, so batching many tenants' replies through one IP shares this budget. There
is no hard HTTP-body byte cap in the app itself, and the bundled reference proxy
config (`deployment/nginx_chatwoot.conf`) sets **`client_max_body_size 0`**, which
in nginx means **no proxy-level body limit**. So request-body size is effectively
bounded only by the app-level limits above (≤ 150k-char `content`, ≤ 40 MB per
attachment) — unless a given Chatwoot deploy overrides `client_max_body_size` to a
smaller value, in which case the proxy rejects oversized bodies (`413`) before
validation. Confirm the value on the target deploy if you plan to send large
attachments.

**(B) Limits YOU must enforce — Chatwoot will not:**

1. **Agentic-AI usage cap (mandatory).** Chatwoot only *displays* `agentic_ai`
   (§5) — there is **no** server-side block. Count AI actions per tenant/period
   and **stop generating replies when over `limits.agentic_ai`** yourself, then
   write the running total back to `custom_attributes.agentic_ai_usage` (§5.1) so
   the dashboard banner reflects reality. If you skip this, nothing caps AI spend.
2. **LLM context / token budget.** An incoming message can be up to 150k chars and
   the history you fetch (§7.7) can be long. Bound what you feed the model
   (windowing, token caps) for cost and context-window safety.
3. **Reply sizing.** Enforce the ≤ 150k-char cap on generated output on your side
   before posting (see A) — fail fast instead of round-tripping a `422`.

**(C) Harden your ingest endpoint (it's a public URL):**

- Verify `X-Chatwoot-Signature` **first** (§7.2), then validate the payload shape.
- Set a sane request-body size limit on your NestJS body parser and reject
  oversized/malformed bodies (a legitimate `message_created` is small — message
  text ≤ 150k chars plus metadata).
- Enforce idempotency (§7.5) before doing any model work.
- Return `2xx` fast for anything you choose to ignore (never `4xx/5xx` a filtered
  event — that triggers Chatwoot's retry machinery).

> **Not redundant:** Chatwoot guards its own API surface (A); you guard your model,
> your queue, and the one limit it delegates to you (B). Both are needed.

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
3. POST /platform/api/v1/accounts/{id}/account_users {user_id, role:"administrator", platform_managed:true}
4. POST /api/v1/accounts/{id}/webhooks       {webhook:{url, subscriptions:["message_created","conversation_status_changed"], platform_managed:true}}  (USER_TOKEN)  → note secret
5. POST /platform/api/v1/users {name:"Acme AI",email,password} → AI_REPLY_TOKEN ;
   POST /platform/api/v1/accounts/{id}/account_users {user_id, role:"agent", platform_managed:true}  (ADR-0006)
6. add the AI user to inbox(es): POST /api/v1/accounts/{id}/inbox_members {inbox_id, user_ids:[ai_user_id]}
   … runtime …
7. contact messages → Chatwoot POSTs message_created (signed) → orchestrator verify+filter → 200
8. worker → LangGraph → POST /api/v1/accounts/{id}/conversations/{cid}/messages {content, message_type:"outgoing"} (AI_REPLY_TOKEN)
9. periodically: PATCH /platform/api/v1/accounts/{id} {limits:{...,agentic_ai}, custom_attributes:{...,agentic_ai_usage}}
   → dashboard banner warns the tenant when consumed >= allowed
```

## 11. Endpoint quick reference

| Method & path | Token | Purpose |
| --- | --- | --- |
| `POST /platform/api/v1/accounts` | PLATFORM | create tenant + limits |
| `PATCH /platform/api/v1/accounts/{id}` | PLATFORM | update limits (full-object) / custom_attributes (merge-patch, §4.1) |
| `POST /platform/api/v1/users` | PLATFORM | create user (admin or AI) → its `access_token` |
| `POST /platform/api/v1/accounts/{id}/account_users` | PLATFORM | attach user; `platform_managed:true` for the admin + AI users (no seat), omit for humans |
| `POST /api/v1/accounts/{id}/webhooks` | USER | subscribe orchestrator to `message_created` (`platform_managed:true`) |
| `POST /api/v1/accounts/{id}/inbox_members` | USER | add the AI reply user to an inbox so it can post there |
| `GET  /enterprise/api/v1/accounts/{id}/limits` | USER | read `{allowed,consumed}` per resource incl. `agentic_ai` |
| `POST /api/v1/accounts/{id}/conversations/{cid}/messages` | AI_REPLY | post AI reply (`message_type:"outgoing"`) |
| `GET  /api/v1/accounts/{id}/conversations/{cid}/messages` | BOT | fetch history for the prompt |

*All paths are relative to `BASE_URL`. All auth via `api_access_token` header.*
