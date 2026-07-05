# Tenant Provisioning Reference

How the external SaaS control plane provisions a tenant using only existing
contracts. Verified against this fork (see
`spec/custom/controllers/platform/api/v1/accounts_controller_spec.rb` and
`spec/custom/controllers/enterprise/api/v1/accounts_controller_spec.rb`).

## Prerequisites (once per installation)

1. Super Admin → Platform Apps → create app; note its `access_token`
   (`PLATFORM_TOKEN` below).
2. Platform APIs work only on self-hosted installs — which this fork is.

## Per-tenant flow

All calls: `-H "api_access_token: $PLATFORM_TOKEN" -H "Content-Type: application/json"`.

### 1. Create the account with plan limits

```sh
curl -X POST "$BASE_URL/platform/api/v1/accounts" -d '{
  "name": "Acme Inc",
  "limits": {
    "agents": 3, "inboxes": 2, "teams": 2, "agent_bots": 1, "webhooks": 2,
    "labels": 20, "custom_attribute_definitions": 10,
    "automation_rules": 5, "integrations": 3
  }
}'
```

Omitted keys default to unlimited. Unknown keys are rejected (422) by the
extended schema in `custom/app/models/custom/account/plan_usage_and_limits.rb`.
Plan upgrades/downgrades are a `PATCH /platform/api/v1/accounts/{id}` with a
new `limits` hash — enforcement picks the new caps up immediately.

`agentic_ai` is also an accepted `limits` key, but it is **display-only**: it is
enforced by the external NestJS backend, not Chatwoot (`EXTERNAL_LIMIT_KEYS`, see
[ENTITLEMENTS.md](./ENTITLEMENTS.md)). Set it here so the dashboard can warn the
tenant; running usage is written to `accounts.custom_attributes['agentic_ai_usage']`.

### 2. Create the tenant admin

```sh
curl -X POST "$BASE_URL/platform/api/v1/users" \
  -d '{"name": "Admin", "email": "admin@acme.test", "password": "<generated>"}'
# → response includes the user id and access_token

curl -X POST "$BASE_URL/platform/api/v1/accounts/$ACCOUNT_ID/account_users" \
  -d '{"user_id": '"$USER_ID"', "role": "administrator", "platform_managed": true}'
```

Note: an `account_users` create normally consumes an **agents** quota seat
(model-level guard on `AccountUser`), so provision limits before adding human
users. The **platform's own service identity** — the `administrator` whose
`USER_TOKEN` drives provisioning and Application-API calls — is created with
`"platform_managed": true` (ADR-0005), which excludes it from the `agents` count
and lets it provision even at the cap. **Human** handoff operators (`role:
agent`) are created **without** the flag and count normally.

### 3. AI-loop plumbing (webhook + AI reply user)

The account webhook (Application API, `USER_TOKEN`) and the AI reply user (Platform
API, `PLATFORM_TOKEN`) are both platform infrastructure, so both carry
`"platform_managed": true` (ADR-0005) — neither consumes a tenant plan slot, and
both provision even when the tenant is at their `webhooks` / `agents` cap:

```sh
# Account webhook → orchestrator ingest URL (platform-managed: consumes NO slot)
curl -X POST "$BASE_URL/api/v1/accounts/$ACCOUNT_ID/webhooks" \
  -H "api_access_token: $USER_TOKEN" \
  -d '{"webhook": {"url": "https://orchestrator.example.com/ingest/'"$TENANT"'",
       "subscriptions": ["message_created", "conversation_status_changed"],
       "platform_managed": true}}'

# AI reply identity: a platform-managed role:agent user (ADR-0006, consumes NO slot)
curl -X POST "$BASE_URL/platform/api/v1/users" \
  -H "api_access_token: $PLATFORM_TOKEN" \
  -d '{"name": "Acme AI", "email": "ai-agent-'"$TENANT"'@handoff.local", "password": "<random>"}'
# → store the returned access_token (AI_REPLY_TOKEN) in the orchestrator's tenant record
curl -X POST "$BASE_URL/platform/api/v1/accounts/$ACCOUNT_ID/account_users" \
  -H "api_access_token: $PLATFORM_TOKEN" \
  -d '{"user_id": '"$AI_USER_ID"', "role": "agent", "platform_managed": true}'
```

`platform_managed` is only honored on the administrator-only / super-admin create
paths, so tenants (who SSO in as `role: agent`) cannot self-exempt. Subscribe to
`conversation_status_changed`, **not** `conversation_resolved` (the latter is a
reporting event, not a webhook event, and fails validation) — detect resolution
from the `status == "resolved"` payload (ADR-0003).

Webhook signing secret: auto-generated per-webhook so the orchestrator can verify
`X-Chatwoot-Signature` (HMAC recipe locked by
`spec/custom/contracts/ai_reply_loop_contract_spec.rb`). Add the AI reply user to the
tenant's inboxes (`POST /api/v1/accounts/{id}/inbox_members`) when inboxes are created,
so it is authorized to post there.

### 4. Store in the control plane / orchestrator

Per tenant: `account_id`, webhook secret, AI reply access token, LangGraph config.

## Reading usage back

`GET /enterprise/api/v1/accounts/{id}/limits` (tenant user token) returns
every quota resource as `{ "allowed": <int|null>, "consumed": <int> }` —
`allowed: null` means unlimited. Platform-managed infrastructure (the AI reply
`role: agent` user, the ingest webhook, the service admin `account_user`) is
excluded from `consumed`,
so counts reflect tenant-created resources only. `agentic_ai` appears in the
response **only when a cap is set**. The dashboard quota UI reads the same
endpoint via the `accounts/limits` store action.

## Quota denial contract (for control-plane error handling)

Create calls that exceed a cap return:

```json
HTTP 402
{ "error": "Account limit exceeded for teams (2/2). Upgrade your plan to add more.",
  "error_code": "quota_exceeded", "resource": "teams", "current": 2, "limit": 2 }
```
