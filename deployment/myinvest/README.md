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

`setup-env.sh` is idempotent and never prints generated values. Before `prepare.sh`, set SMTP and the selected Claude provider credentials in `.env`. Keep signup disabled. The default is an EU Bedrock inference profile; direct Anthropic additionally requires a completed processing-region/DPA review and `ALLOW_DIRECT_ANTHROPIC=true`. `prepare.sh` runs Chatwoot's database preparation/migrations and therefore needs the explicit human production-migration approval required by the operating policy.

The generated `IMPORT_ID_HMAC_KEY` is a separate, durable key for pseudonymous source mappings during historical imports. It is included only in encrypted recovery metadata and is never passed to the running Chatwoot or Claude services.

For a local proof stack, set `LOCAL_SMOKE=true`, `BIND_ADDRESS=127.0.0.1`, and use localhost Caddy overrides, then run `scripts/e2e.sh`. It creates synthetic local records only and proves signed delivery, durable handoff, duplicate suppression, and cross-account rejection; it refuses to run in production mode.

The initial password exists only in `.env` as `ADMIN_PASSWORD`. Log in as `ADMIN_EMAIL`, change that password immediately, enable MFA, then remove `ADMIN_PASSWORD` from `.env` after bootstrap. Re-running bootstrap does not change an existing user's password or duplicate accounts/memberships.

## WhatsApp and channels

Configure channels inside the matching account, never in the shared installation context:

1. Create a Meta WhatsApp Cloud inbox for `MyInvest Pro` and attach the SaaS support number.
2. Create a separate inbox for `Academy Neu` and its number/routing.
3. Keep legacy contacts, templates, and the old number in `Academy Alt`.
4. Assign agents and teams separately in each account; verify with one inbound and one outbound template message per number.

Meta/WABA tokens belong in Chatwoot's channel settings, never in this repository or custom attributes. They are protected by the database/storage boundary and the encrypted recovery snapshot. A single installation provides application-level tenant separation. Use separate stacks/databases if a contractual or regulatory requirement demands physical isolation.

## Claude agent handoff

The `claude-agent` service builds from `../../integrations/myinvest-claude-agent` and talks to Chatwoot over `http://rails:3000`. Chatwoot sends signed AgentBot webhooks through the public `/_agent/webhooks/chatwoot` route, so private-network SSRF access stays disabled. Bootstrap creates one website inbox and one account-scoped Agent Bot per account, connects each pair, and writes the canonical `TENANTS_JSON` keys `saas`, `new_academy`, and `legacy_academy` atomically to `.env`; no credential is printed. It then builds and starts the agent.

1. Attach the generated `MyInvest Claude Support` bot only to the intended inboxes in its own account.
2. Never place provider credentials in Chatwoot custom attributes or knowledge-base documents.
3. After a provider-setting change, recreate only the agent: `docker compose up -d --build --force-recreate claude-agent`.
4. Test signature rejection, tenant isolation, escalation, opt-out, and an unknown-answer case before enabling auto-replies.

Keep the knowledge sources scoped by account/tenant in the agent. Retrieved content must never cross the three account boundaries.

## Backups and restore

`backup.sh` briefly pauses writers to create an application-consistent snapshot containing both databases, local Active Storage, Redis, an exact S3 object-version manifest, encrypted recovery metadata, and checksums. For production S3 it refuses to run unless bucket versioning is enabled and every database-referenced object version exists:

```bash
./scripts/backup.sh
```

Set `BACKUP_GPG_RECIPIENT` to the offline recovery key. Schedule the script from the host, for example daily at 02:30 UTC, and copy completed snapshot directories to encrypted off-host storage. Local retention defaults to 14 days. Test restores on an isolated host regularly. Restore requires the current `.env` to match the encrypted recovery metadata; if the host was lost, decrypt that file out-of-band into `.env` first.

Restore is destructive and is intentionally never automatic. It stops application services, recreates both databases, replaces Chatwoot and Redis volumes, and restores every S3 key to the version recorded with the database snapshot. After explicit human approval:

```bash
RESTORE_CONFIRMATION=restore:20260816T023000Z \
  ./scripts/restore.sh ./backups/20260816T023000Z
./scripts/smoke.sh
```

## Operations

### Historical support chats

Historical chat bundles are tenant-bound and explicitly excluded from the Claude knowledge base. The Academy website exporter accepts its Neon connection only through the process environment and writes a mode-`0700` bundle with mode-`0600` files:

```bash
SOURCE_DATABASE_URL='postgresql://…' ./scripts/export-neon-support-history.sh /secure/path/academy-history
```

The export is fixed to `new_academy`; it refuses other channels, unknown roles, empty messages, existing output directories, and any knowledge import. Delete the restricted raw bundle after the idempotent Chatwoot import has been verified.

After a verified backup, validate and import a bundle with its exact tenant/source confirmation. Local smoke stacks prefix the value with `local-`:

```bash
CHAT_IMPORT_BACKUP_CONFIRMED=true \
CHAT_IMPORT_CONFIRMATION='import:new_academy:neon_academy_website_support' \
  ./scripts/import-chat-history.sh /secure/path/academy-history
```

The wrapper runs the importer twice, requires the second pass to create no records, verifies the tenant ledger and bot-free inbox, and asserts that the Claude knowledge-document count remains unchanged.

Useful read-only checks:

```bash
docker compose ps
docker compose logs --tail=200 rails sidekiq claude-agent
curl --fail https://support.myinvest-pro.de/health
```

For upgrades, read the Chatwoot release notes, create a fresh backup, update the exact version and digest in `compose.yaml`, run `validate.sh`, apply the approved database preparation, and finish with `bootstrap.sh` plus `smoke.sh`. Never switch this stack to a floating `latest` tag.

If changing the domain, update `CADDY_SITE_ADDRESS` and `FRONTEND_URL` together. Caddy manages ACME certificates automatically; preserve both Caddy volumes across redeployments.
