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

### 2. Create the tenant admin

```sh
curl -X POST "$BASE_URL/platform/api/v1/users" \
  -d '{"name": "Admin", "email": "admin@acme.test", "password": "<generated>"}'
# → response includes the user id and access_token

curl -X POST "$BASE_URL/platform/api/v1/accounts/$ACCOUNT_ID/account_users" \
  -d '{"user_id": '"$USER_ID"', "role": "administrator"}'
```

Note: `account_users` creation consumes an **agents** quota seat (model-level
guard on `AccountUser`), so provision limits before adding users.

### 3. AI-loop plumbing (webhook + bot)

Using the tenant admin's `access_token` (`USER_TOKEN`) against the
Application API:

```sh
# Account webhook → orchestrator ingest URL (consumes one webhooks slot)
curl -X POST "$BASE_URL/api/v1/accounts/$ACCOUNT_ID/webhooks" \
  -H "api_access_token: $USER_TOKEN" \
  -d '{"webhook": {"url": "https://orchestrator.example.com/ingest/'"$TENANT"'",
       "subscriptions": ["message_created"]}}'

# Agent bot to author AI replies (consumes one agent_bots slot)
curl -X POST "$BASE_URL/api/v1/accounts/$ACCOUNT_ID/agent_bots" \
  -H "api_access_token: $USER_TOKEN" \
  -d '{"name": "AI Assistant", "outgoing_url": ""}'
# → store the bot access_token in the orchestrator's tenant record
```

Webhook signing secret: set per-webhook so the orchestrator can verify
`X-Chatwoot-Signature` (HMAC recipe locked by
`spec/custom/contracts/ai_reply_loop_contract_spec.rb`). Attach the bot to the
tenant's inboxes (`agent_bot` inbox association) when inboxes are created.

### 4. Store in the control plane / orchestrator

Per tenant: `account_id`, webhook secret, bot access token, LangGraph config.

## Reading usage back

`GET /enterprise/api/v1/accounts/{id}/limits` (tenant user token) returns
every quota resource as `{ "allowed": <int|null>, "consumed": <int> }` —
`allowed: null` means unlimited. The dashboard quota UI reads the same
endpoint via the `accounts/limits` store action.

## Quota denial contract (for control-plane error handling)

Create calls that exceed a cap return:

```json
HTTP 402
{ "error": "Account limit exceeded for teams (2/2). Upgrade your plan to add more.",
  "error_code": "quota_exceeded", "resource": "teams", "current": 2, "limit": 2 }
```
