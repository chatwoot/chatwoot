# AI Reply Loop

The AI orchestrator is an **external service** (LangGraph pipeline). This repo
contributes zero new endpoints to the loop — only per-tenant provisioning.
Everything below rides on contracts Chatwoot already ships.

> **Status (2026-07-03): Chatwoot side complete; orchestrator lives elsewhere.**
> No Chatwoot code change was needed — the signing recipe, `X-Chatwoot-Delivery`
> idempotency key, and the `message_type == "incoming"` self-loop guard are all
> stock and are pinned by `spec/custom/contracts/ai_reply_loop_contract_spec.rb`
> (green). Provisioning of the webhook + AI reply token per tenant is documented and
> spec-verified (see PROVISIONING.md). The signature/idempotency/filter/reply
> **implementation** and the manual end-to-end run belong to the external
> orchestrator repo — the contract it must honor is CHATWOOT_ENGINE_INTEGRATION.md.

## Sequence

```text
Contact sends message
  → Chatwoot fires account webhook `message_created` (signed)
    → Orchestrator: verify signature → dedupe → filter → enqueue → 200 OK
      → Worker: fetch context → LangGraph → reply | no-op
        → POST message-create API (AI reply token) → Chatwoot delivers to contact
```

## Per-tenant provisioning (the only Chatwoot-side work)

For each tenant account, the control plane provisions via existing APIs:

1. An **account webhook** subscribed to `message_created` (optionally
   `conversation_status_changed`), pointing at the orchestrator's ingest URL,
   with a per-tenant secret. Created with `platform_managed: true`, so it is
   excluded from the tenant's `webhooks` quota (ENTITLEMENTS.md, ADR-0005) — no
   slot is reserved.
2. An **AI reply identity** to author replies: a per-tenant `role: agent`
   `account_user` (the canonical AI identity, ADR-0006) added as a member of the
   target inboxes, created with `platform_managed: true` so it never burns a human
   `agents` seat (excluded from the count, ADR-0005). Its `access_token` authors the
   `outgoing` replies. (ADR-0002 proposed an `AgentBot` here; never built, and
   `platform_managed` made it unnecessary.)
3. Orchestrator-side tenant record mapping `account_id` → webhook secret, API
   token, LangGraph config.

## Signature verification (must match `lib/webhooks/trigger.rb:54-63`)

Headers on every delivery (when a secret is configured):

- `X-Chatwoot-Timestamp`: unix seconds as string
- `X-Chatwoot-Signature`: `sha256=` + hex HMAC-SHA256(secret, `"{timestamp}.{raw_request_body}"`)
- `X-Chatwoot-Delivery`: unique delivery id

Verification rules:

1. Reject if either signature header is missing (401).
2. Compute HMAC over the **raw** body bytes (before any JSON parsing).
3. Constant-time comparison.
4. Reject if `|now - timestamp| > 300s` (replay window).
5. Look up the secret by tenant (from URL path or payload `account.id` —
   but only trust `account.id` *after* the signature verifies against that
   tenant's secret; safest is a per-tenant ingest path).

## Idempotency

Treat every delivery as potentially repeated (Chatwoot retries on failure).

- Key: `X-Chatwoot-Delivery` primarily; additionally dedupe on
  `(account_id, message.id)` because retries of a *different* delivery can
  carry the same message.
- Store: Redis `SET key 1 NX EX 86400`. If the key exists → 200 OK, no work.
- Mark processed **after** the reply posts successfully (or after a definitive
  no-op decision), so a crashed worker retries; make the reply post itself
  safe by checking for an existing bot reply to that message id first.

## Loop-prevention filter (run before enqueueing)

Process the event only if **all** hold:

| Check | Field in `message_created` payload |
| --- | --- |
| It's a message event | `event == "message_created"` |
| Inbound from the contact | `message_type == "incoming"` |
| Not a private note | `private == false` |
| Authored by a contact | `sender.type`/sender shape is Contact, not User |
| Not the bot's own message | sender id ≠ provisioned bot identity |
| Conversation eligible | `conversation.status` is `open`/`pending` per product rules; skip when a human has taken over (e.g. handoff label/attribute) |

Everything else → acknowledged (2xx) and dropped. Never 4xx/5xx a message you
merely chose to ignore — that triggers Chatwoot's retry machinery.

## Reply path

`POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages`
with the bot/agent token (`api_access_token` header), body:

```json
{ "content": "<reply>", "message_type": "outgoing" }
```

The resulting message will itself fire `message_created` — it fails the
`message_type == incoming` filter, which is the structural guarantee against
self-reply loops (the sender check is defense in depth).

Context fetching (conversation history for the LangGraph prompt) uses the
existing list-messages API on the same conversation, same token.

## Operational rules

- Ingest endpoint does verification + dedupe + filter + enqueue only; target
  <100ms. All model calls happen in workers.
- Worker outcomes: `reply`, `no_op` (both mark processed), `retryable_error`
  (bounded retries with backoff, then dead-letter + alert).
- Log per event: delivery id, account id, message id, decision, latency.
- No-op must be a first-class outcome — the pipeline deciding "a human should
  handle this" is success, not failure.

## Test matrix (orchestrator repo, plus regression here)

- Signature: valid accepted; invalid/missing rejected; stale timestamp
  rejected.
- Idempotency: same delivery id twice → one reply; same message id under two
  delivery ids → one reply.
- Filters: outgoing, private, bot-authored, resolved-conversation events
  produce no AI work.
- End-to-end: incoming message → LangGraph stub → reply visible in
  conversation via API; conversation state valid; exactly one reply.
- Regression (this repo): existing webhook specs and message-create specs
  unchanged and green.
