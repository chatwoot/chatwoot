# Deploying this fork on Railway

This fork replaces the stock `ghcr.io/railwayapp-templates/chatwoot:Community`
image with **your own build** from source, so you can edit Chatwoot and redeploy.

## Architecture

| Railway service | Role | Config file |
|---|---|---|
| **Chatwoot** | Rails web (Puma) + public URL | `railway.toml` |
| **Chatwoot Worker** | Sidekiq background jobs | `railway.worker.toml` |
| **Postgres** | pgvector database | (managed) |
| **Valkey** | Redis / Sidekiq queue | (managed) |

The web service runs `db:chatwoot_prepare` before each deploy (migrations).
**Never change `SECRET_KEY_BASE` on a live install** — Sidekiq must share the same value.

## Making changes

1. Edit code in this repo (`app/`, `app/javascript/`, etc.).
2. Commit and push to `develop` (or your deploy branch).
3. Railway rebuilds and redeploys automatically (GitHub-connected services).

Local dev: see upstream [Chatwoot docs](https://developers.chatwoot.com/contributing-guide).

## Required env vars (web + worker)

Both services need the same core vars:

- `DATABASE_URL` → Postgres internal URL
- `REDIS_URL` → Valkey internal URL
- `SECRET_KEY_BASE` → **same on both services**
- `FRONTEND_URL` → public Chatwoot URL (web sets this; worker reads it)
- `RAILS_ENV=production`
- `NODE_ENV=production`
- `INSTALLATION_ENV=docker`
- `ACTIVE_STORAGE_SERVICE=local` (volume mounted at `/app/storage`)

## Upstream merges

```bash
git fetch upstream
git checkout develop
git merge upstream/develop   # or rebase
git push origin develop
```

Resolve conflicts in Rails/Vue as needed, then let Railway deploy.

## Integration with company-chat

The Next.js app (`company-chat` on Vercel) forwards WhatsApp webhooks here and
opens agent inboxes via `NEXT_PUBLIC_CHATWOOT_URL`. Changing Chatwoot UI/API
does not require redeploying company-chat unless you change webhook paths or auth.
