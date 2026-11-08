# Production deploy

How Chatwoot and ai-service run in production and how to release a change
(DEV-Johnstocker/chatwoot#1). This repository is public: hostnames of internal
tools, IP addresses, IDs and secrets are not written here. The owner holds
them; on John's machine they are in the workspace `.env.supabase` and Claude's
memory notes.

## What runs

Dokploy (v0.31) on the VPS deploys `ai-service/deploy/dokploy-compose.yml` from
branch `develop` of this fork. Auto-deploy is off.

| Service | Profile | Notes |
|---|---|---|
| `rails` | always | Chatwoot `v4.19.1`; runs `db:chatwoot_prepare` then Puma. Healthy when `/api` answers |
| `sidekiq` | always | Starts after `rails` is healthy, so jobs never meet an unmigrated schema |
| `redis` | always | Password in a private config file; append-only |
| `ai-service` | `ai` | Built from `ai-service/`; VPS loopback `127.0.0.1:18080` for `/admin` over SSH |
| `cloudflared` | `admin` | Cloudflare Tunnel for `https://ai-admin.johnstockeraistudio.com`; ingress forwards only `^/admin` |

Production sets `COMPOSE_PROFILES=ai,admin`. There is no Postgres service:
both apps use Supabase.

## Routing

Traefik (managed by Dokploy) serves `https://chat.johnstockeraistudio.com`:

- `/webhooks/chatwoot` → `ai-service:8080` (the Agent Bot webhook URL).
- everything else → `rails:3000`.

These domain rules live in the Dokploy UI, not in git. If you change them,
update this section in the same PR.

## Environment

Set in the Dokploy environment tab. Names only; values never go in git or in
a chat.

- Chatwoot: `SECRET_KEY_BASE`, `FRONTEND_URL`, `CHATWOOT_DATABASE_URL`,
  `REDIS_PASSWORD`, `MAILER_SENDER_EMAIL`, `SMTP_ADDRESS`, `SMTP_PORT`,
  `SMTP_USERNAME`, `SMTP_PASSWORD`. A missing required value fails the deploy
  (`${VAR:?}`).
- ai-service: `CHATWOOT_BOT_TOKEN`, `CHATWOOT_WEBHOOK_SECRET`,
  `AI_ADMIN_PASSWORD`, `AI_DATABASE_URL`, `LLM_BASE_URL`, `LLM_API_KEY`,
  `LLM_MODEL`, `LLM_FALLBACK_*`, `EMBED_BASE_URL`, `EMBED_API_KEY`,
  `EMBED_MODEL`. Settings saved on `/admin` override the `LLM_*`/`EMBED_*`
  values.
- Tunnel: `CF_TUNNEL_TOKEN`.
- GitHub Actions secrets (not Dokploy) for the nightly answer smoke check:
  `SMOKE_LLM_BASE_URL`, `SMOKE_LLM_API_KEY`, `SMOKE_LLM_MODEL`,
  `SMOKE_EMBED_BASE_URL`, `SMOKE_EMBED_API_KEY`, `SMOKE_EMBED_MODEL`. Use a
  separate, spend-limited key; it never touches production.
- Compose: `COMPOSE_PROFILES=ai,admin`, `COMPOSE_BAKE=false`.

## Staging

A second Dokploy app on the same VPS runs `deploy/dokploy-compose.staging.yml`
(DEV-Johnstocker/chatwoot#37). It is the production stack with its own
Postgres 17 + pgvector container instead of Supabase, memory and CPU caps
(about 2.3 GB in total; about 1 GB in use when idle), services named `stg-*`,
and no public route: one Cloudflare Tunnel serves both hostnames behind
Cloudflare Access. **Never add a Dokploy domain to the staging app**, and keep
its *Isolated Deployment* on, so staging never shares a network with
production.

| Hostname | Goes to | Access |
|---|---|---|
| `chat-staging.johnstockeraistudio.com` | `stg-rails:3000`, except `/webhooks/chatwoot` → `stg-ai-service:8080` | owner emails; `/webhooks/chatwoot` bypasses Access (HMAC-signed), added only after the real webhook secret is set |
| `ai-admin-staging.johnstockeraistudio.com` | `stg-ai-service:8080`, only `^/admin` | owner emails |

Inside the stack, ai-service calls Chatwoot at `http://stg-rails:3000`
(`FORCE_SSL` is off; Cloudflare terminates TLS). Staging data is fake: never
copy production customer data into it. `/admin` over SSH:
`ssh -N -L 8082:127.0.0.1:18081 llmopshostinger` → `http://localhost:8082/admin`.

**Environment (staging app, Dokploy):** `SECRET_KEY_BASE`, `FRONTEND_URL`
(`https://chat-staging.johnstockeraistudio.com`), `STAGING_DB_PASSWORD`,
`AI_DB_PASSWORD` (ai-service's own database role), `REDIS_PASSWORD`,
`AI_ADMIN_PASSWORD`, `CF_TUNNEL_TOKEN` (the staging tunnel's, not
production's), `LLM_API_KEY`/`EMBED_API_KEY` (the spend-limited CI key),
`LLM_MODEL`, `EMBED_MODEL`, `CHATWOOT_BOT_TOKEN`, `CHATWOOT_WEBHOOK_SECRET`
(both required: random placeholders from `openssl rand -hex 32` until the
Agent Bot exists), `COMPOSE_PROFILES` (empty until the bot exists, then
`ai`), `COMPOSE_BAKE=false`. SMTP is optional.
Never reuse a production secret. The staging compose ID goes in the
workspace `.env.supabase` as `DOKPLOY_STAGING_COMPOSE_ID`.

**Commands:** `dokploy.py --target staging status|deploy|verify`. It refuses
if the staging compose ID equals production's, refuses a deploy with less
than 10 GB free on the VPS, and `verify` checks that Access guards
`/api`, `/installation/onboarding` and the staging `/admin`. Seed the sample shop and
check answers in one step:

```bash
ssh llmopshostinger 'docker exec <staging-app>-stg-ai-service-1 /answer-eval \
  -seed-kb /testdata/sample-kb/faq.json -cases /testdata/answers-smoke.json -min-pass 0.8 -strict-faithful'
```

`-seed-kb` refuses an account that already holds knowledge it did not add.

**Reset** (destroys staging data only): stop the staging app in Dokploy,
delete its `postgres_data`, `redis_data`, `storage_data` and `ai_data`
volumes, then redo first-time setup steps 4–6 below.

**First-time setup (owner):**

1. Dokploy → the project → *Create service* → *Compose*: name `chatwoot-staging`,
   provider GitHub, this repository, branch `develop`, compose path
   `ai-service/deploy/dokploy-compose.staging.yml`, auto-deploy off. No domains.
2. Cloudflare Zero Trust → *Networks → Tunnels* → create tunnel
   `chatwoot-staging` (cloudflared). Copy its token into the staging env as
   `CF_TUNNEL_TOKEN`. Public hostnames: `chat-staging` (any path) →
   `http://stg-rails:3000`; `ai-admin-staging` path `^/admin` →
   `http://stg-ai-service:8080`.
3. Cloudflare Zero Trust → *Access → Applications*: one app for
   `chat-staging.johnstockeraistudio.com` and `ai-admin-staging…` with an
   *Allow* policy for the owner emails. Do this **before** the first deploy:
   Chatwoot's onboarding page lets the first visitor create the super admin.
4. Fill the staging env (above) with `COMPOSE_PROFILES` empty, deploy, then
   `dokploy.py --target staging verify`.
5. Chatwoot first login (through Access): create the super admin on the
   onboarding page, an account, a Website inbox, and an Agent Bot whose
   webhook URL is `https://chat-staging.johnstockeraistudio.com/webhooks/chatwoot`.
6. Put the bot's real token and secret in the staging env, set
   `COMPOSE_PROFILES=ai`, deploy again. Only now add the tunnel route
   `chat-staging` path `^/webhooks/chatwoot` → `http://stg-ai-service:8080`
   (above the catch-all) and a second Access app for
   `chat-staging.johnstockeraistudio.com/webhooks/chatwoot` with a *Bypass*
   policy (Everyone). Then seed the sample shop (above).

## Release a change

In Claude Code, run `/deploy` (`ai-service/.claude/skills/deploy/`): it runs
steps 3–5 below with the checks, using `dokploy.py status|deploy|verify`.
Without Claude Code, follow the steps by hand.

1. Open a PR into `develop`; CI (`.github/workflows/ai-service.yml`) must pass
   on the exact head. Merge with `gh pr merge --match-head-commit <sha>`.
2. Schema change? Follow `../AGENTS.md` §5 first: backup → apply → check tables
   and the `vector` extension. `Postgres.Migrate` applies new versions on start.
3. Check that no other deploy is running: Dokploy → Deployments, or the API
   `deployment.allByCompose`. Two sessions once deployed ten minutes apart.
4. Get the owner's go-ahead, then deploy: Dokploy → Deploy, or the API
   `compose.deploy` (`POST /api/compose.deploy` with header `x-api-key`).
5. Verify:
   - all containers up; `rails` and `redis` healthy; `sidekiq` without errors;
   - `https://chat.johnstockeraistudio.com/api` → 200 and `/app/login` → 200;
   - `/admin` on the public domain → 404;
   - an unsigned `POST /webhooks/chatwoot` → 401;
   - `ai-admin.johnstockeraistudio.com/admin` asks for Cloudflare Access.

Rollback: revert the PR, merge, deploy again. Rolling back code does not roll
back a schema change.

- Below schema v7 code (or while old and new replicas overlap), an app approved
  by a team member can become a grant with no approver, which removing that
  member does not disconnect. After such a rollback, check
  `SELECT id, client_name, created_at FROM oauth_grants WHERE approved_by IS NULL
  AND created_at > '<rollback time>'` and disconnect unexpected ones on
  Connect AI tools.
- Below schema v11 code, data feeds are not understood: an older binary may
  check a feed's file as if it were a web page, and removing a feed there
  leaves its row documents behind. Before such a rollback, remove the data
  files on Knowledge base (which deletes their rows), or accept that the
  older code keeps the rows it last saved.
- Below schema v4 code, expired and scheduled knowledge comes back: older code
  ignores `valid_from`/`valid_until`. Before such a rollback, delete or edit
  dated documents whose window is closed, or accept that the bot may quote
  them again.

## Restore drill

A backup counts only once it has been restored. `restore-drill.sh` restores a
`pg_dump -Fc` backup of the ai-service database into a throwaway
`pgvector/pgvector:pg17` container (data in RAM, port on 127.0.0.1 only,
removed on exit) and runs `restore-check`: `Migrate`, then the `vector`
extension, the schema version, every table `Migrate` creates, minimum row
counts and one vector query. It prints counts only, never row content. Run it
on the host that keeps the backups, so customer data stays there.

```bash
# on your machine, from ai-service/
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -o restore-check ./cmd/restore-check
# copy restore-check and deploy/restore-drill.sh to the backup host, then there:
./restore-drill.sh <backup>.dump ./restore-check -min-rows kb_documents=1,kb_chunks=1,business_profiles=1
```

Exit 0 = pass, 1 = a check failed, 2 = the restore itself failed. Use the
Postgres major version of the source database (`RESTORE_DRILL_IMAGE`); a
Supabase dump needs its `extensions` schema, which the script recreates.
`restore-check` reads `RESTORE_DATABASE_URL` and refuses any non-local host,
so it cannot migrate production by mistake. Evidence and open gaps:
`restore-drill.contract.md`.

## Scheduled backups

`backup.sh` runs daily at 03:00 (VPS time, Asia/Bangkok) from a systemd
timer: a read-only `pg_dump -Fc -n public` of the production ai-service
database (URL read from the running container, pgx `pool_*` options
stripped, never printed), a `.sha256` next to it, then the restore drill on
that dump. Only after the drill passes does it delete dumps older than the
newest `BACKUP_KEEP_DAYS` dates (default 7); a dump that fails the drill is
kept as `aisvc-failed-*.dump` and older backups stay untouched.

Install or update on the VPS (as root), from the reviewed commit:

```bash
install -d -m 700 /opt/aisvc-backup
install -m 700 deploy/backup.sh deploy/restore-drill.sh restore-check /opt/aisvc-backup/
install -m 600 deploy/backup/aisvc-backup.env.example /etc/aisvc-backup.env   # first time; set BACKUP_SOURCE_CONTAINER
install -m 644 deploy/backup/aisvc-backup.service deploy/backup/aisvc-backup.timer /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now aisvc-backup.timer
systemctl start aisvc-backup.service          # one run now
journalctl -u aisvc-backup.service -n 50      # result: "OK ... verified"
systemctl list-timers aisvc-backup.timer      # next run
```

`restore-check` is the Linux build from "Restore drill" above. Tests for the
URL cleaning and retention: `bash deploy/backup_test.sh` (CI runs them).
Not covered yet: an offsite copy and an alert when a run fails (the journal
records it).

## Access

- SSH: `ssh llmopshostinger` (key-based alias on the owner's machine; plain
  root login is refused).
- `/admin` over SSH: `ssh -N -L 8081:127.0.0.1:18080 llmopshostinger`, then
  `http://localhost:8081/admin`.

## Gotchas

- Rails runs with `FORCE_SSL`. Plain `http://rails:3000` calls get redirected,
  so ai-service uses the public HTTPS URL, and the healthcheck sends
  `X-Forwarded-Proto: https`. The image has `busybox wget` but no curl.
- `${VAR:-}` passes an empty string, which overrides Chatwoot's
  `ENV.fetch(name, default)`. Required values use `${VAR:?}` instead.
- Compose does not recreate a container when only `depends_on` changes.
- Never set `SAFE_FETCH_ALLOW_PRIVATE_NETWORK`.
