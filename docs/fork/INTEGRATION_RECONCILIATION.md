# Integration Reconciliation — meta-saas ↔ Chatwoot fork

**Purpose:** reconcile the two integration contracts (this repo's
[CHATWOOT_ENGINE_INTEGRATION.md](./CHATWOOT_ENGINE_INTEGRATION.md) and the
meta-saas monorepo's `meta-saas ↔ Chatwoot` guide) against **actual Chatwoot
code**, and give a copy-paste runbook for standing both up side by side in local
dev. Every "Chatwoot reality" row below is verified in this tree.

---

## 1. What already matches (no change on either side)

| meta-saas expects | Chatwoot reality (verified) | Verdict |
| --- | --- | --- |
| Signed webhook: `X-Chatwoot-Signature: sha256=HMAC_SHA256(secret,"{ts}.{rawBody}")`, `X-Chatwoot-Timestamp`, `X-Chatwoot-Delivery` | `lib/webhooks/trigger.rb:54-63` emits exactly these over the raw JSON body | ✅ byte-for-byte |
| Replay window / raw-body HMAC | signed string is `"{ts}.{body}"` where `body` is the exact serialized payload | ✅ verify against raw bytes, never re-serialized JSON |
| Secret at `payload.webhook.secret` | `app/views/api/v1/accounts/webhooks/create.json.jbuilder` wraps `payload.webhook`; `_webhook.json.jbuilder:6` exposes `secret` | ✅ |
| Secret auto-generated, not settable | `WebhookSecretable` (`has_secure_token`); `webhook_params` permits only `inbox_id,name,url,subscriptions` | ✅ read it from the create response |
| Platform `POST /users` returns `access_token` | `app/views/platform/api/v1/models/_user.json.jbuilder:1` → top-level `access_token` | ✅ works for both service-admin and bot flows |
| Post reply via `.../conversations/{id}/messages {content, message_type:"outgoing"}` | stock Application API | ✅ |
| Capacity-quota create denials as structured `402` | `custom/.../webhooks_controller.rb` + peers → `check_quota` → `render_payment_required` | ✅ |
| `account_users` (agents) over-cap → `422` (model guard) | `custom/app/models/custom/account_user.rb` model-level guard | ✅ handle both 402 and 422 |
| `agentic_ai` accepted as a limit key | `EXTERNAL_LIMIT_KEYS = %w[agentic_ai]` in `plan_usage_and_limits.rb` | ✅ schema-valid, display-only |

**Webhook signing is not fork-added** — it is already in OSS `trigger.rb`. So the
meta-saas contract's open question "confirm your signature scheme" is answered:
**it matches.**

---

## 2. Divergences resolved (action required on the meta-saas side)

### 2.1 🔴 `conversation_resolved` is not a subscribable webhook event — ADR-0003

- **meta-saas had:** `subscriptions: ["message_created","conversation_resolved","conversation_status_changed"]` (its endpoint #16).
- **Chatwoot reality:** `Webhook::ALLOWED_WEBHOOK_EVENTS` (`app/models/webhook.rb:32`) has **no** `conversation_resolved` — it is a reporting event only. `validate_webhook_subscriptions` rejects the array → **422, webhook never created, AI loop silently broken.**
- **Resolution:** subscribe to `["message_created","conversation_status_changed"]`; detect resolution from `conversation_status_changed` where `status == "resolved"` (meta-saas already handles this in its ingest). **Change the subscription array in `chatwoot-api.adapter.ts`.**

### 2.2 🟢 AI reply identity: platform-managed `role: agent` user — ADR-0006 (was ADR-0002)

- **meta-saas does:** the AI posts as a per-tenant Platform user with `role: agent`.
- **The original concern (ADR-0002):** `custom/app/services/custom/entitlement_service.rb` counted `agents: account.account_users.count`, so a plain agent user **burned a human `agents` seat**. ADR-0002 proposed an `AgentBot` (counted under `agent_bots`, not `agents`) to avoid that.
- **Resolution (shipped, ADR-0006 + ADR-0005):** the AgentBot was **not** needed and was **never built**. Instead, the AI reply `account_user` is stamped **`platform_managed: true`**, which `EntitlementService` excludes from the `agents` count entirely. The `role: administrator` **service** user and the account **webhook** are flagged the same way. Verified live: with the AI user, service admin, and webhook all present, `usage(:agents) == 0` and `usage(:webhooks) == 0`. meta-saas keeps its `role: agent` AI user (`ChatwootApiAdapter.createAiAgent`) — now sending `platform_managed: true`.

### 2.3 🟢 Subscription list for status events (informational)

meta-saas also listed `conversation_status_changed` — that one **is** valid and is
now the single resolution signal (see 2.1). No change beyond dropping
`conversation_resolved`.

---

## 3. Chatwoot-side actions from this reconciliation

**None required in code.** The Chatwoot fork already satisfies the contract; the
fixes are on the meta-saas side (§2). Documentation was updated:

- `CHATWOOT_ENGINE_INTEGRATION.md` — AI reply identity is the platform-managed
  `role: agent` user (ADR-0006), and the `conversation_resolved` trap called out.
- ADRs [0001](./adr/0001-chatwoot-single-messaging-gateway.md)–
  [0006](./adr/0006-ai-reply-identity-platform-managed-agent-user.md) record the
  decisions ([0002](./adr/0002-agentbot-canonical-ai-identity.md) superseded by
  [0006](./adr/0006-ai-reply-identity-platform-managed-agent-user.md)).
- [SYSTEM_ARCHITECTURE.md](./SYSTEM_ARCHITECTURE.md) — ownership matrix + flows.

> **Update (ADR-0005 + ADR-0006, shipped & verified live):** the AI-identity quota
> concern is resolved **without** an AgentBot. The Chatwoot side has a
> `platform_managed` flag on `agent_bots`, `webhooks`, and `account_users`; flagged
> infrastructure is excluded from quota counts and never blocked. meta-saas now sends
> `platform_managed: true` on the **AI reply `role: agent` account_user**, the account
> webhook, and the automation service admin user — verified live (`usage(:agents)=0`,
> `usage(:webhooks)=0` on a fresh account). The AgentBot proposed in ADR-0002 was never
> built and is not needed.

---

## 4. Local side-by-side runbook (no real WhatsApp)

**Local ports (this setup):**

| Service | Repo | Local URL |
| --- | --- | --- |
| Chatwoot fork (this repo) | chatwoot | `http://localhost:3000` |
| NestJS control plane + LangGraph API | meta-saas | `http://localhost:3001` |
| Next.js dashboard | meta-saas | `http://localhost:3002` |

So: `CHATWOOT_BASE_URL=http://localhost:3000`, the meta-saas API is `3001`
(`PUBLIC_API_URL` derives from it), and the tenant-facing login lives on the
Next.js app at `3002` (what `EXTERNAL_LOGIN_URL` points at).

Two directions, two URLs — this is the part that bites in local dev:

- **meta-saas → Chatwoot** uses `CHATWOOT_BASE_URL` (e.g. `http://localhost:3000`).
- **Chatwoot → meta-saas** uses the URL baked into the inbox/webhook at provision
  time, derived from meta-saas's `PUBLIC_API_URL`. If Chatwoot runs in Docker and
  the meta-saas API on the host, Chatwoot **cannot** reach `localhost:3001` — set
  `PUBLIC_API_URL=http://host.docker.internal:3001` (add
  `--add-host=host.docker.internal:host-gateway` to the Chatwoot container on
  Linux) or use the host LAN IP. Set it **before** provisioning.

### 4.1 Chatwoot side (this repo)

```bash
# Docker-only toolchain (see CLAUDE.md). Bring up the app:
docker compose up rails sidekiq vite     # Chatwoot on http://localhost:3000

# Create a Platform App token: Super Admin → Platform Apps → create → copy access_token
#   → this is meta-saas's CHATWOOT_PLATFORM_TOKEN.
# (Optional) lock down native auth so the Next.js stack is the only way in:
#   ENABLE_SSO_ONLY_LOGIN=true, EXTERNAL_LOGIN_URL=http://localhost:3002/login, ENABLE_ACCOUNT_SIGNUP=false
```

### 4.2 meta-saas side (its repo)

Set in `apps/api/.env` (see the meta-saas guide §6.1), the load-bearing ones:

```bash
CHATWOOT_ENABLED=true
OUTBOUND_ENABLED=true            # must be true to actually send replies
CHATWOOT_BASE_URL=http://localhost:3000
CHATWOOT_PLATFORM_TOKEN=<from 4.1>
CHATWOOT_WEBHOOK_SECRET=<shared secret, single-tenant fallback>
PUBLIC_API_URL=http://host.docker.internal:3001   # reachable FROM Chatwoot
```

Then run infra + API and register a tenant (auto-provisions account, inbox, the
**platform-managed AI reply user** (`role: agent`), and the account webhook subscribed to
`["message_created","conversation_status_changed"]`):

```bash
docker compose up -d                         # meta-saas Postgres/Redis/MinIO
cd apps/api && pnpm prisma migrate deploy && pnpm db:seed && pnpm dev
curl -sX POST http://localhost:3001/provisioning/register \
  -H 'content-type: application/json' \
  -d '{"tenantName":"Test Co","adminEmail":"admin@test.co","password":"password123"}'
```

### 4.3 Drive the loop

1. In Chatwoot, create a contact + conversation in the tenant's **API-channel
   inbox** and post an **incoming** message (API or widget).
2. Watch meta-saas logs: signature verified → filtered → enqueued → `Agent
   answered …` → `Outbound … sent on chatwoot`.
3. The reply appears in the same Chatwoot conversation.
4. **Quota/handoff checks:** exhaust the agentic-AI allowance → AI pauses
   (`automation.blocked`, no reply, manual replies still work); resolve the
   conversation → AI resumes.

### 4.4 First-run gotchas

| Symptom | Cause | Fix |
| --- | --- | --- |
| Webhook create returns 422 | subscribed to `conversation_resolved` | drop it (ADR-0003) |
| Every signature fails | HMAC over re-serialized JSON, not raw bytes | verify against exact received body |
| Chatwoot can't reach meta-saas | `PUBLIC_API_URL=localhost` inside Docker | use `host.docker.internal` or LAN IP, re-provision |
| AI uses a human agent seat | AI `role: agent` user created without the flag | send `platform_managed: true` on the AI account_user (ADR-0005/0006) |
| Reply loop / bot answers itself | not filtering on `message_type=="incoming"` | filter incoming-only before enqueue |
| AI user/webhook eats a plan slot | created without `platform_managed: true` | set the flag on the AI reply user, webhook, and service admin user (ADR-0005/0006) |
</content>
