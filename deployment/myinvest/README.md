# MyInvest Support Platform

This directory runs one pinned Chatwoot installation with three application-level account boundaries:

- `MyInvest Pro` for the SaaS product
- `Academy Neu` for the current Academy
- `Academy Alt` for the legacy Academy

PostgreSQL, Redis, Rails, Sidekiq, and the Claude agent are reachable only on the internal Docker network. Caddy is the only service publishing host ports. The Claude agent owns a separate PostgreSQL database/user and Redis database; it has no public port. The mounted security initializer suppresses Active Job arguments and redacts Chatwoot's retry warning so signing secrets and customer payloads cannot enter Rails/Sidekiq logs.

## First production installation

Prerequisites are a dedicated EU host (minimum 4 vCPU/8 GB RAM), Docker Engine with Compose v2, GnuPG, public ports 80/443, EU object storage with bucket versioning enabled, and DNS for `support.myinvest-pro.de` pointing at the host. Run commands from this directory:

```bash
./scripts/setup-env.sh
chmod 600 .env
${EDITOR:-vi} .env
./scripts/validate.sh
./scripts/prepare.sh
./scripts/bootstrap.sh
./scripts/smoke.sh
```

`setup-env.sh` is idempotent and never prints generated values. Before `prepare.sh`, set SMTP and the selected model provider in `.env`. Keep signup disabled. The DGX profile defaults to the local OpenAI-compatible Ollama endpoint on the dedicated Docker bridge (`172.30.240.1`); the host service itself is loopback-only and the validator pins both endpoint and `qwen3:8b`. EU Bedrock remains supported. Direct Anthropic additionally requires a completed processing-region/DPA review and `ALLOW_DIRECT_ANTHROPIC=true`. `prepare.sh` runs Chatwoot's database preparation/migrations and therefore needs the explicit human production-migration approval required by the operating policy.

The generated `IMPORT_ID_HMAC_KEY` is a separate, durable key for pseudonymous source mappings during historical imports. It is included only in encrypted recovery metadata and is never passed to the running Chatwoot or Claude services.

### DGX Spark interim host

`dgx-workloads` (`spark-4527`) can run this stack as an explicitly accepted interim host, but it is shared infrastructure and does not satisfy the dedicated-host prerequisite above. Keep the Docker volumes on the host NVMe and use Cloudflare only as the public edge. The host-side production environment for the private DGX fabric path is:

```dotenv
CADDY_SITE_ADDRESS=support.myinvest-pro.de
CADDY_SITE_SCHEME=http
INGRESS_MODE=cloudflare_tunnel
BIND_ADDRESS=127.0.0.1
HTTP_PORT=80
HTTPS_PORT=443
FRONTEND_URL=https://support.myinvest-pro.de
```

Run the named Cloudflare Tunnel connector on `spark-4527` itself and route `support.myinvest-pro.de -> http://127.0.0.1:80`. Caddy is loopback-only, so customer traffic never traverses the shared DGX fabric in plaintext. Caddy pins `X-Forwarded-Proto=https` toward Rails, so secure cookies and `FORCE_SSL` remain correct behind the public Cloudflare TLS edge. The validator deliberately rejects a remote/private-fabric Caddy bind in tunnel mode.

The named Docker volumes survive container recreation and host reboot, but all of them live on the same single NVMe as `/var/lib/docker`. The interim DGX profile runs MinIO only on the internal Docker network with bucket versioning enabled (`STORAGE_LOCAL_MINIO=true`, `STORAGE_ENDPOINT=http://minio:9000`, `STORAGE_FORCE_PATH_STYLE=true`, `DIRECT_UPLOADS_ENABLED=false`). Uploads are proxied through Chatwoot because browsers cannot reach the private MinIO hostname. `BACKUP_DIR` on that disk is only mode-`0700` staging, not disaster recovery. In production `backup.sh` keeps plaintext staging only while writers are paused, then AEAD-encrypts the whole completed snapshot, uploads and remotely verifies it, retains only the encrypted local archive plus receipt, and removes the plaintext staging tree. Never copy plaintext recovery files to another cluster node.

For a local proof stack, set `LOCAL_SMOKE=true`, `BIND_ADDRESS=127.0.0.1`, and use localhost Caddy overrides, then run `scripts/e2e.sh`. It creates synthetic local records only and proves signed delivery, durable handoff, duplicate suppression, and cross-account rejection; it refuses to run in production mode.

The initial password exists only in `.env` as `ADMIN_PASSWORD`. Log in as `ADMIN_EMAIL`, change that password immediately, enable MFA, then remove `ADMIN_PASSWORD` from `.env` after bootstrap. Re-running bootstrap does not change an existing user's password or duplicate accounts/memberships.

### Support structure

Preview the tenant-scoped teams, labels, inbox memberships, and safe routing/priority automations with the default dry run:

```bash
SUPPORT_ROSTERS_JSON="$(cat /secure/support-rosters.json)" \
  ./scripts/bootstrap-support-structure.rb
```

Apply only with the exact production confirmation:

```bash
SUPPORT_ROSTERS_JSON="$(cat /secure/support-rosters.json)" \
  SUPPORT_STRUCTURE_CONFIRMATION=provision-support-structure:production \
  ./scripts/bootstrap-support-structure.rb --apply
```

`SUPPORT_ROSTERS_JSON` must contain exactly the three tenant keys. Each tenant contains `inboxes`, keyed by every live inbox name, and `teams`, keyed by both canonical managed team names; every value is a non-empty array of account-user email identities. First-line and escalation rosters are explicit and may differ. Unknown or duplicate identities fail before writes. Administrators remain authorized through `AccountUser` but are not made assignable unless explicitly listed.

The command requires exactly one canonical account for each tenant key, distinct account IDs, and no unkeyed account adopting a canonical display name. It updates only managed records and never sends customer messages or deletes unrelated configuration. Managed team rosters are provisioned and verified exactly. Explicit inbox support users are added while existing InboxMembers, including the bootstrap administrator, are preserved. Every live inbox has auto-assignment disabled so the conversation-created automation routes directly to the explicit nonempty first-line team without a pre-team round-robin race. History imports are identified durably by `Channel::Api.additional_attributes.myinvest_history_import=true`, with a conservative name fallback. They are excluded from routing and roster changes, and fail validation if they have an API channel `webhook_url`, Inbox webhook, enabled integration hook, bot, or auto-assignment. Response targets are operational metadata in each account's `support_operations` custom attribute; the command neither creates nor claims an Enterprise SLA. Output contains counts and tenant keys only—no user details, credentials, or message content.

## WhatsApp and channels

Configure channels inside the matching account, never in the shared installation context:

1. Create a Meta WhatsApp Cloud inbox for `MyInvest Pro` and attach the SaaS product support number.
2. Create a separate inbox for `Academy Neu` and its number/routing.
3. Keep legacy contacts, templates, and the old number in `Academy Alt`.
4. Assign agents and teams separately in each account; verify with one inbound and one outbound template message per number.

### WhatsApp cutover for `legacy_academy`

Use the cutover wrapper only after the legacy HubSpot channel has been de-activated; the wrapper reads the HubSpot Conversations API and refuses to proceed while the configured channel account is still active or authorized. Set the Meta phone number, phone number ID, WABA ID, access token, app secret, and HubSpot credentials in `.env`, then run with the exact confirmation:

```bash
CUTOVER_CONFIRMATION='cutover-whatsapp:legacy_academy:+491234567890' \
  ./scripts/cutover-whatsapp.rb
```

The wrapper validates the confirmation, paginates HubSpot `conversations/v3/conversations/channel-accounts`, and refuses to proceed while the configured channel account is still active or authorized. It then invokes a Rails provisioner that:

- creates or reuses the `legacy_academy` WhatsApp inbox keyed by phone number;
- fails closed on cross-account or mismatched WABA/phone-ID conflicts;
- sets the `whatsapp_cloud` provider config including `app_secret`;
- registers only the Meta webhook callback (never the phone number) and converts provider failures to generic cutover errors;
- verifies Meta health: exact phone, WABA, business portfolio, `CONNECTED`/`VERIFIED`/`CLOUD_API`, non-risky quality rating, and webhook callback;
- attaches the tenant's `MyInvest Claude Support` AgentBot only after health passes;
- assigns an existing account administrator to the inbox;
- never prints secrets or places them on argv.

Re-runs are safe: a matching existing channel is reused and the same verification steps are applied. If health verification fails, fix the Meta-side configuration and rerun with the same confirmation; the AgentBot is attached only on a passing health check.

Meta/WABA tokens belong in Chatwoot's channel settings, never in this repository or custom attributes. They are protected by the database/storage boundary and the encrypted recovery snapshot. A single installation provides application-level tenant separation. Use separate stacks/databases if a contractual or regulatory requirement demands physical isolation.

### Google Workspace email prerequisites

Native Google OAuth email channels require a dedicated shared mailbox per semantic tenant. Personal mailbox ingestion is forbidden because it would break tenant boundaries and expose private correspondence to the review/quarantine knowledge model. Configure OAuth once at installation scope:

```dotenv
GOOGLE_OAUTH_CLIENT_ID=...
GOOGLE_OAUTH_CLIENT_SECRET=...
```

`GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` are optional but paired: `validate.sh` fails closed if exactly one is set. They are passed only to `rails` and `sidekiq`; the validator rejects any other service receiving `GOOGLE_OAUTH_CLIENT_SECRET`. Chatwoot builds the Google callback from `FRONTEND_URL`; do not set a separate callback env. Each tenant inbox must connect to its own shared mailbox address; never reuse or forward a personal inbox into a tenant channel.

### Native channel readiness preflight

Before creating native Email, Instagram DM, or WhatsApp channels, set `CHANNEL_READINESS_CONFIG_JSON` to an array whose tenant key/account pairs exactly equal the complete canonical `TENANTS_JSON` set; omitted, duplicate, nonexistent, or mismatched mappings block the entire assessment. Every channel needs a public `name`, matching `inbox_account_id`, exact `human_inbox_member_ids` and `expected_human_inbox_member_ids` rosters, `provider_health: "ready"`, `callback_verified: true`, and `bot_attached: false`. Email also needs `mailbox` and `dedicated_shared_mailbox_confirmed: true`. Instagram needs numeric `business_id`, `page_id`, and `account_id`, the complete `permissions` list (`instagram_manage_messages`, `pages_manage_metadata`, and `pages_show_list`), and `access_token_env`. WhatsApp needs an E.164 `phone_number`, numeric `waba_id`, `phone_number_id`, and `hubspot_channel_account_id`, plus `access_token_env`, `app_secret_env`, `hubspot_owner`, and the existing exact `cutover-whatsapp:<tenant>:<phone>` confirmation. These `*_env` values must name `CHANNEL_READINESS_*` variables containing credentials; credentials must not be placed directly in the manifest. Set `HUBSPOT_CUTOVER_CONFIRMED=true` only after ownership and deactivation are independently confirmed. The three Active Record encryption variables must be configured before credentials can pass preflight.

All provider health, callback, ownership, and roster fields in this manifest are declarative plans, not authoritative observations. A complete declaration can therefore report only `human_status: "planned"`; every channel remains `status: "blocked"` with `runtime_verification_required` until a future authoritative runtime verifier observes the live state. No self-attested channel returns ready. Bot attachment additionally requires a tenant/channel-specific reviewed auto-reply evaluation recorded as `auto_reply_evaluation_approved: true`; missing approval adds the redacted `auto_reply_evaluation_unapproved` reason. This approval is independent of retrieval ranking: `KNOWLEDGE_MIN_SCORE` is an FTS rank, not a probability or confidence threshold. If a tenant declares `history_inbox`, its account and human roster must match and `callback_count`, `hook_count`, `bot_attached`, and `auto_assignment_enabled` must declare that the inbox is inert, while runtime verification remains required.

Run the fail-closed preflight from this directory:

```bash
./scripts/channel-readiness.rb
```

The host wrapper needs Docker Compose v5 but no host Ruby. It uses `deployment/myinvest/.env` by default (or `ENV_FILE`) only for Compose interpolation of the existing Rails service allowlist. A first no-network one-off validates the exact tenant manifest and restricted `CHANNEL_READINESS_*` credential references using a mode-`0600` env file containing only `TENANTS_JSON` and `CHANNEL_READINESS_CONFIG_JSON`. The wrapper then builds a second mode-`0600` env file containing those fixed fields, the optional cutover confirmation flag, and only credential assignments explicitly referenced by that validated manifest; a trap removes all temporary files. Deployment-only admin, PostgreSQL-admin, MinIO-root, Anthropic/AWS, backup, and agent-database secrets are never passed through `--env-from-file`. The command starts the pinned `rails` image with `--no-deps` and does not connect to providers, send messages, create channels, or register webhooks. Its exact declarative JSON contract contains `version`, `dry_run`, `assessment`, overall `status`, and tenant/channel statuses plus fixed reason codes. It emits tenant keys and configured public channel names only; mailbox addresses, phone numbers, provider/account IDs, owners, OAuth values, tokens, app secrets, confirmations, environment-variable names, and env-file contents are never emitted. Duplicate email mailboxes, Instagram identifiers, or WhatsApp identities across tenants block every affected channel.

## Claude agent handoff

The `claude-agent` service builds from `../../integrations/myinvest-claude-agent` and talks to Chatwoot over `http://rails:3000`. Chatwoot sends signed AgentBot webhooks through the public `/_agent/webhooks/chatwoot` route, so private-network SSRF access stays disabled. Bootstrap creates one website inbox and one account-scoped Agent Bot per account, connects each pair, and writes the canonical `TENANTS_JSON` keys `saas`, `new_academy`, and `legacy_academy` atomically to `.env`; no credential is printed. It then builds and starts the agent.

1. Attach the generated `MyInvest Claude Support` bot only to the intended inboxes in its own account.
2. Never place provider credentials in Chatwoot custom attributes or knowledge-base documents.
3. After a provider-setting change, recreate only the agent: `docker compose up -d --build --force-recreate claude-agent`.
4. Test signature rejection, tenant isolation, escalation, opt-out, and an unknown-answer case before enabling auto-replies.

Keep the knowledge sources scoped by account/tenant in the agent. Retrieved content must never cross the three account boundaries.

## Backups and restore

`backup.sh` briefly pauses writers to create an application-consistent snapshot containing both databases, local Active Storage, Redis, the complete local MinIO volume, an exact S3 object-version manifest, encrypted recovery metadata, and checksums. In production it then invokes `offsite-backup.sh`: the whole snapshot is stream-encrypted with OpenPGP AEAD/OCB/AES-256, uploaded to `BACKUP_OFFSITE_REMOTE`, and read back from the remote for a ciphertext SHA-256 comparison. It refuses to run unless bucket versioning is enabled and every database-referenced object version exists:

```bash
./scripts/backup.sh
```

Set `BACKUP_GPG_RECIPIENT` to the offline recovery key and `BACKUP_OFFSITE_REMOTE` to a configured rclone destination such as `recovery:MyInvest/Backups/Chatwoot`. Schedule the script from the host, for example daily at 02:30 UTC. Local retention defaults to 14 days. The adjacent `*.offsite-receipt.json` records the immutable remote path and ciphertext SHA-256 without secrets; the only retained local payload is `*.tar.gpg`.

`backup.sh` holds a host-user-wide `flock` under `$XDG_STATE_HOME` (or `~/.local/state`) for its complete lifetime. A second invocation fails before it pauses a service or creates plaintext staging, including when the two invocations originate from different immutable release directories.

Run a real non-destructive recovery proof regularly on an isolated recovery host that has the offline private key. Use the remote and checksum from that receipt; the command downloads the ciphertext, verifies its SHA-256, authenticates/decrypts the AEAD archive, and checks every inner snapshot file before discarding its temporary directory:

```bash
./scripts/verify-offsite-backup.sh \
  ./backups/20260816T023000Z.offsite-receipt.json
```

Only after this proof should a restore be approved. Materialize plaintext only inside the isolated recovery root, using the same receipt; the recovery script refuses an existing target and needs an exact confirmation:

```bash
RECOVERY_CONFIRMATION=recover:20260816T023000Z \
  ./scripts/recover-offsite-backup.sh \
  ./backups/20260816T023000Z.offsite-receipt.json /secure/recovery
```

`restore.sh` requires the current `.env` to match the encrypted recovery metadata; if the host was lost, decrypt that file out-of-band into `.env` first. Remove the materialized plaintext recovery directory after the approved restore proof; the encrypted archive and receipt remain the durable artifacts.

Restore is destructive and is intentionally never automatic. It stops application services, recreates both databases, replaces Chatwoot and Redis volumes, and restores every S3 key to the version recorded with the database snapshot. After explicit human approval:

```bash
RESTORE_CONFIRMATION=restore:20260816T023000Z \
  ./scripts/restore.sh ./backups/20260816T023000Z
AGENT_STATE_RECONCILE_CONFIRMATION=reconcile:support.myinvest-pro.de \
  ./scripts/reconcile-agent-state.sh
./scripts/smoke.sh
PRODUCTION_E2E_CONFIRMATION=test:support.myinvest-pro.de ./scripts/e2e-production.sh
```

The restore keeps Caddy, Sidekiq, and the agent stopped until reconciliation finishes. Restored BullMQ agent keys are isolated only in the database selected by `CLAUDE_AGENT_REDIS_URL`, renamed under a run-tagged namespace, and given a verified TTL no longer than `DELIVERY_RETENTION_SECONDS`; raw queued payloads therefore cannot persist unbounded. Reconciliation compares every agent delivery/state key with the restored Chatwoot tenant, message, conversation, and creation time while public ingress and asynchronous writers are paused. A stale delivery is operationally neutralized with a negative conversation marker and a terminal status. The agent may reclaim it only when the immutable incoming-message timestamp is newer than the preserved ledger timestamp, so its own stale queued job stays suppressed. Stale handoff states are neutralized to `active`. A second run must report zero remaining mismatches.

The production E2E creates two clearly marked synthetic visitors through the externally routed website-widget API, not through Rails. It proves Cloudflare/Caddy/Chatwoot ingress, an AgentBot handoff, exactly one sourced reply visible again through the public widget API, HMAC/replay/tenant rejection, then resolves the synthetic conversations and retires the temporary knowledge document without deleting production records.

## Operations

### Historical support chats

Historical chat bundles are tenant-bound and explicitly excluded from the Claude knowledge base. The Academy website exporter accepts its Neon connection only through the process environment and writes a mode-`0700` bundle with mode-`0600` files:

```bash
SOURCE_DATABASE_URL='postgresql://…' ./scripts/export-neon-support-history.sh /secure/path/academy-history
```

The HubSpot exporter accepts its token and exact inbox/channel allowlist only through the process environment. It writes complete source-event archives, full original email bodies, and local digest-addressed file attachments without retaining signed URLs. Mixed MyInvest24 histories belong only in the bot-free `legacy_academy` history inbox with `knowledge_import=false`; they are brand/source archives, not Academy knowledge classification.

The export is fixed to `new_academy`; it refuses other channels, unknown roles, empty messages, existing output directories, and any knowledge import. Delete the restricted raw bundle after the idempotent Chatwoot import has been verified.

After a verified backup, validate and import a bundle with its exact tenant/source confirmation. Local smoke stacks prefix the value with `local-`:

```bash
CHAT_IMPORT_BACKUP_CONFIRMED=true \
CHAT_IMPORT_CONFIRMATION='import:new_academy:neon_academy_website_support' \
  ./scripts/import-chat-history.sh /secure/path/academy-history
```

The wrapper runs the importer twice, requires the second pass to create no records, verifies the tenant ledger and bot-free inbox, and asserts that the Claude knowledge-document count remains unchanged.

When restoring a local Chatwoot snapshot into the production S3-compatible profile, migrate every existing Active Storage blob before opening the service. The migration verifies the database service names, MinIO versioning and object count, and downloads every blob to compare its checksum:

```bash
STORAGE_MIGRATION_CONFIRMATION=migrate:local:s3_compatible \
  ./scripts/migrate-storage-to-s3.sh
```

Useful read-only checks:

```bash
docker compose ps
docker compose logs --tail=200 rails sidekiq claude-agent
curl --fail https://support.myinvest-pro.de/health
```

For upgrades, read the Chatwoot release notes, create a fresh backup, update the exact version and digest in `compose.yaml`, run `validate.sh`, apply the approved database preparation, and finish with `bootstrap.sh`, `smoke.sh`, and `e2e-production.sh`. Never switch this stack to a floating `latest` tag.

If changing the domain, update `CADDY_SITE_ADDRESS` and `FRONTEND_URL` together. Caddy manages ACME certificates automatically; preserve both Caddy volumes across redeployments.
