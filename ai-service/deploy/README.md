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
- Compose: `COMPOSE_PROFILES=ai,admin`, `COMPOSE_BAKE=false`.

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
- Below schema v4 code, expired and scheduled knowledge comes back: older code
  ignores `valid_from`/`valid_until`. Before such a rollback, delete or edit
  dated documents whose window is closed, or accept that the bot may quote
  them again.

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
