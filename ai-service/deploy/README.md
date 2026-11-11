# Production deploy

How Chatwoot and ai-service run in production and how to release a change
(DEV-Johnstocker/chatwoot#1). This repository is public: hostnames of internal
tools, IP addresses, IDs and secrets are not written here. The owner holds
them; on John's machine they are in the workspace `.env.supabase` and Claude's
memory notes.

## What runs

Dokploy (v0.31) on the VPS deploys `ai-service/deploy/dokploy-compose.yml` from
branch `production` of this fork (staging deploys `develop`). Auto-deploy is
off. Only a promote (below) or `/deploy` moves `production`, so a redeploy
never picks up develop commits nobody approved.

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

Traefik (managed by Dokploy) serves `https://pronto.johnstockeraistudio.com`:

- `/webhooks/chatwoot` → `ai-service:8080` (the Agent Bot webhook URL).
- everything else → `rails:3000`.

These domain rules live in the Dokploy UI, not in git. If you change them,
update this section in the same PR.

The old host `chat.johnstockeraistudio.com` (the address before the Pronto
rename on 2026-11-09) is proxied by Cloudflare and a zone redirect rule sends
every request to the same path on `pronto.` with a 308. The Messenger
callback in the Meta app is `https://pronto.johnstockeraistudio.com/bot`.
Keep the DNS records under `chat.`: Resend's sending records for
`alerts@chat.johnstockeraistudio.com` live there. The two Dokploy domains for
`chat.` are left in place, so removing the redirect rule and un-proxying the
record is a complete rollback.

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
  values. Optional: `EMBED_FALLBACK_*` (backup route to the same embedding
  model), `REPLY_DELAY` (default `4s`), `CHATWOOT_READER_TOKEN`.
- `CHATWOOT_READER_TOKEN` is the access token of a dedicated Chatwoot user,
  "AI Reader", used to re-read chats and to assign handoffs by workload. Keep
  that user an **Agent** (never Administrator), a member **only** of the
  inboxes the bot answers, and **Offline** (it is never given chats, but an
  online status adds noise). Its token can act as an agent in those inboxes,
  so treat it as a password. Create the `bot-handoff` label in Chatwoot
  (Settings, Labels) so the handoff label shows in filters.
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
| `pronto-staging.johnstockeraistudio.com` | `stg-rails:3000`, except `/webhooks/chatwoot` → `stg-ai-service:8080` | owner emails; `/webhooks/chatwoot` bypasses Access (HMAC-signed), added only after the real webhook secret is set |
| `ai-admin-staging.johnstockeraistudio.com` | `stg-ai-service:8080`, only `^/admin` | owner emails |

The old staging host `chat-staging.johnstockeraistudio.com` redirects (308)
to `pronto-staging` through the same Cloudflare redirect rule set.

Inside the stack, ai-service calls Chatwoot at `http://stg-rails:3000`
(`FORCE_SSL` is off; Cloudflare terminates TLS). Staging data is fake: never
copy production customer data into it. `/admin` over SSH:
`ssh -N -L 8082:127.0.0.1:18081 llmopshostinger` → `http://localhost:8082/admin`.

**Environment (staging app, Dokploy):** `SECRET_KEY_BASE`, `FRONTEND_URL`
(`https://pronto-staging.johnstockeraistudio.com`), `STAGING_DB_PASSWORD`,
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
   `pronto-staging.johnstockeraistudio.com` and `ai-admin-staging…` with an
   *Allow* policy for the owner emails. Do this **before** the first deploy:
   Chatwoot's onboarding page lets the first visitor create the super admin.
4. Fill the staging env (above) with `COMPOSE_PROFILES` empty, deploy, then
   `dokploy.py --target staging verify`.
5. Chatwoot first login (through Access): create the super admin on the
   onboarding page, an account, a Website inbox, and an Agent Bot whose
   webhook URL is `https://pronto-staging.johnstockeraistudio.com/webhooks/chatwoot`;
   connect the bot to the inbox. The URL must be the public one: Chatwoot
   refuses webhook hosts without a public IP ("has no public ip addresses"),
   so `http://stg-ai-service:8080` does not work in production mode.
6. Put the bot's real token and secret in the staging env, set
   `COMPOSE_PROFILES=ai`, deploy again. Only now add the tunnel route
   `chat-staging` path `^/webhooks/chatwoot` → `http://stg-ai-service:8080`
   and drag it to **first place** (routes match top to bottom; below the
   catch-all it never matches), plus a second Access app for
   `pronto-staging.johnstockeraistudio.com/webhooks/chatwoot` with a *Bypass*
   policy (Everyone). Then seed the sample shop into the bot's account
   (`-seed-account <id>`; the first account Chatwoot creates is not always 1).

**Auto-deploy (#38):** `.github/workflows/ai-service-staging.yml` runs after
the `ai-service` CI succeeds on a push to `develop`. It deploys staging,
runs `verify` and the answer smoke check on staging, and sets the commit
status `staging` (pending → success/failure). One run at a time; a newer
commit replaces a queued one. A failed check leaves the new version running
and marks `staging` red. Manual run with *fail_verify* proves the red path.

- Dokploy: the token in `DOKPLOY_STAGING_API_KEY` belongs to a member user
  that can reach the staging environment only; every run first checks it
  cannot read the production compose and stops if it can.
- VPS: the key in `STAGING_SSH_KEY` is bound in `/root/.ssh/authorized_keys`
  to the forced command `/usr/local/bin/staging-ci`
  (`deploy/staging/staging-ci.sh`), which accepts only `free-gb`,
  `containers` and `smoke`. `smoke` seeds the sample café (FAQs and
  business profile from `testdata/sample-kb/`) into its own test account
  9001 and runs every case there, so whatever is tried on the real staging
  accounts cannot change the release check. Cases the AI provider could not
  finish (429 on the primary and the fallback) are reported as skipped and
  left out of the pass rate; at least 5 must complete. After changing the script,
  copy it to `/usr/local/bin/staging-ci` on the VPS again. When appending to `authorized_keys`, make sure
  the file ends with a newline first: a key glued onto the previous line
  breaks both keys.

## Promote to production

The usual release (#39). After a PR merges into `develop`, CI passes and the
staging workflow deploys and checks it (commit status `staging`). When that
staging run ends green, the promote workflow starts by itself on the newest
develop commit with green staging, and the owner gets one approval request.
It can also be run by hand: **Actions → ai-service promote → Run workflow** (or
`gh workflow run ai-service-promote.yml -f sha=<sha>`; empty = newest develop
commit with green staging).

No approval request is sent when production would not change: the range holds
only docs and tests (`*.md`, `ai-service/docs/`, `*_test.go`, the deploy and
promote `test_*.py`), or an automatic run finds production already on the
commit. `production` then stays where it is, and the next real promote ships
those commits too. `testdata/` counts as a real change: the image ships it.

A run waiting for approval holds the production queue. A newer automatic run
waits behind it (GitHub keeps only the newest waiting one); reject the older
run to let the newer one go, or approve it and the newer one follows.


1. `check` (no secrets) refuses a commit that is not on `develop`'s
   first-parent line, has no green `staging` status from the staging workflow,
   is older than production, or whose range can change a production database
   (`internal/knowledge/schema*.sql`, `internal/knowledge/postgres.go`, or
   `deploy/dokploy-compose.yml`, where a Chatwoot image bump runs Chatwoot's
   migrations). Its summary lists what would ship. `dry_run` stops here.
2. `promote` waits in the GitHub Environment `production` until the owner
   approves. It then fast-forwards `production` to the commit, deploys,
   checks that Dokploy deployed exactly that commit, and runs `verify` (public
   checks; the job has no SSH key, so container health is not read).
3. If deploy or verify fails after the branch moved, it moves `production`
   back to the previous commit and redeploys it.

Secrets: `DOKPLOY_URL` and `DOKPLOY_COMPOSE_ID` (repository) and
`DOKPLOY_PRODUCTION_API_KEY` (environment `production` only). The environment
has the owner as required reviewer and admits runs from `develop` only, so the
key never reaches a workflow file from another branch. Agents never approve a
pending production deployment; only the owner clicks it.

## Release a change by hand

For a schema change (the promote refuses it: the backup comes first) or when
GitHub is unavailable. In Claude Code, run `/deploy`
(`ai-service/.claude/skills/deploy/`): it runs steps 3–5 below with the
checks, using `dokploy.py status|deploy|verify`. Without Claude Code, follow
the steps by hand. Step 4 moves `production` first:
`git push origin <sha>:refs/heads/production` (fast-forward only).

1. Open a PR into `develop`; CI (`.github/workflows/ai-service.yml`) must pass
   on the exact head. Merge with `gh pr merge --match-head-commit <sha>`.
2. Schema change? Follow `../AGENTS.md` §5 first: backup → apply → check tables
   and the `vector` extension. `Postgres.Migrate` applies new versions on start.
   After the deploy, rebuild `restore-check` from the deployed commit and
   reinstall it in `/opt/aisvc-backup/` (see "Scheduled backups"): it checks
   the schema version and table list compiled into it, so an old binary fails
   the next nightly drill and sends a false alert.
3. Check that no other deploy is running: Dokploy → Deployments, or the API
   `deployment.allByCompose`. Two sessions once deployed ten minutes apart.
4. Get the owner's go-ahead, then deploy: Dokploy → Deploy, or the API
   `compose.deploy` (`POST /api/compose.deploy` with header `x-api-key`).
5. Verify:
   - all containers up; `rails` and `redis` healthy; `sidekiq` without errors;
   - `https://pronto.johnstockeraistudio.com/api` → 200 and `/app/login` → 200;
   - `/admin` on the public domain → 404;
   - an unsigned `POST /webhooks/chatwoot` → 401;
   - `ai-admin.johnstockeraistudio.com/admin` asks for Cloudflare Access.

Rollback: move `production` back to the previous commit and deploy (the promote
workflow does this itself when verify fails), or revert the PR, merge and
promote again. Rolling back code does not roll
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
URL cleaning, retention and offsite settings: `bash deploy/backup_test.sh`
(CI runs them).

**Offsite copy (Cloudflare R2).** After the drill passes, the dump and its
`.sha256` are uploaded to `daily/` in a private R2 bucket with `curl
--aws-sigv4` (no extra tools). The upload carries the SHA-256, which R2
checks, and a HEAD afterwards must match the local size. A bucket lifecycle
rule deletes `daily/` objects after 30 days and aborts unfinished uploads
after 1 day. Set `R2_BACKUP_ENDPOINT` and `R2_BACKUP_BUCKET` in
`/etc/aisvc-backup.env`, and the keys of an R2 token limited to that bucket
(Object Read & Write) in `/etc/aisvc-backup-r2.env`, mode 600. An upload
failure keeps the verified local backup and exits 3, which marks the
systemd run failed. To restore from R2: download `daily/<name>` and its
`.sha256`, run `sha256sum -c`, then `restore-drill.sh` or `pg_restore`.

**Failure alert (email via Resend, and Slack).** `aisvc-backup.service` has
`OnFailure=aisvc-backup-alert@%n.service`, so `deploy/backup/alert.sh` runs
only when a backup run fails (exit 1, 2 or 3, timeout or kill) and sends the
unit, exit status in plain words and the last 30 log lines to every
configured channel; one failing does not stop the other. A successful run
sends nothing. Settings in `/etc/aisvc-backup-alert.env` (mode 600):
`RESEND_BACKUP_ALERT_KEY` (Resend key with Sending access for the sender's
domain only) and `ALERT_TO` for email; `SLACK_BACKUP_WEBHOOK_URL` (incoming
webhook of a Slack app with only the `incoming-webhook` scope, posting to
the project channel) for Slack. Install alongside the backup:

```bash
install -m 700 deploy/backup/alert.sh /opt/aisvc-backup/
install -m 644 'deploy/backup/aisvc-backup-alert@.service' /etc/systemd/system/
systemctl daemon-reload
# test the real path with a unit that fails on purpose:
systemd-run --unit=aisvc-backup-alerttest -p OnFailure=aisvc-backup-alert@aisvc-backup-alerttest.service.service /bin/sh -c 'exit 3'
```

Tests: `bash deploy/backup/alert_test.sh` (CI runs them).

## Model provider check (Slack)

On 2026-11-10 the OpenAI key behind both bots ran out of credit. Nothing
alerted, and the staging smoke check was the first sign. Now
`aisvc-openai-check.timer` runs `deploy/monitor/openai-check.sh` every 30
minutes on the VPS. For each running `*ai-service-1` container (production
and staging) it does two things:

- It sends one tiny embeddings request with the key and base URL from that
  container's env (`EMBED_*`, falling back to `LLM_*`). The cost is about
  $0.0000002 per run.
- When the primary fails, it probes the embeddings fallback
  (`EMBED_FALLBACK_*`). If the fallback answers, the state is a ⚠️ warning
  ("answering through fallback"), not a ❌ failure.
- It counts quota errors in the last 35 minutes of the container's log.
- When the container has a `META_PAGE_TOKEN` (Facebook comment leads), it asks
  Meta's `debug_token` whether that token is still valid. A rejected token is
  a ❌, a token expiring within 14 days is a ⚠️, both with a daily reminder.
  Containers without a Page token are skipped.

It posts to Slack `#chatwoot-ai-service` through the backup alert's webhook
(`SLACK_BACKUP_WEBHOOK_URL` in `/etc/aisvc-backup-alert.env`) in these
cases only:

- a target starts failing: out of credit, key rejected, or rate limit,
  server errors or no answer twice in a row;
- the failure changes kind;
- every 6 hours while it stays down;
- once when it recovers.

State is kept in `/var/lib/aisvc-openai-check/`. Keys go to curl through a
root-only config file and are never printed. Optional settings go in
`/etc/aisvc-openai-check.env` (`OPENAI_CHECK_CONTAINERS`, `REMIND_HOURS`).
Install or update:

```bash
install -d -m 700 /opt/aisvc-monitor
install -m 700 deploy/monitor/openai-check.sh /opt/aisvc-monitor/
install -m 644 deploy/monitor/aisvc-openai-check.service deploy/monitor/aisvc-openai-check.timer /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now aisvc-openai-check.timer
systemctl start aisvc-openai-check && journalctl -u aisvc-openai-check -n 20
```

Tests: `bash deploy/monitor/openai-check_test.sh` (CI runs them).

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
