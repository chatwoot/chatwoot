# AirysChat — Deployment Guide

## Overview

AirysChat is deployed on a single VPS via **Docker Swarm**, fronted by **Traefik** as a reverse proxy. The Docker image is built automatically by GitHub Actions and pushed to **GHCR** on every push to `develop`.

```
GitHub (develop branch)
    └─► GitHub Actions → Build Docker image → Push to GHCR
                                                   │
                                          VPS (37.27.190.170)
                                          Docker Swarm Stack
                                          ├─ chatwoot_app      (Rails, :3000)
                                          ├─ chatwoot_sidekiq  (Sidekiq workers)
                                          ├─ chatwoot_litellm  (LiteLLM proxy, :4000)
                                          ├─ chatwoot_redis    (Redis, :6379)
                                          └─ pgvector          (Postgres+pgvector, external stack)
```

---

## Infrastructure

| Resource | Value |
|---|---|
| VPS IP | `37.27.190.170` |
| OS | Ubuntu 24.04.4 |
| RAM | 15 GB |
| Domain | `chatwoot.airys.com.br` |
| SSL | Let's Encrypt via Traefik `letsencryptresolver` |
| Docker network | `airys` (external) |
| Stack file | `/root/chatwoot.yaml` |
| LiteLLM config | `/root/litellm.yml` |

---

## CI/CD Pipeline

**Workflow file:** [`.github/workflows/publish_airyschat_ghcr.yml`](../.github/workflows/publish_airyschat_ghcr.yml)

- Triggers on push to `develop` or any `v*` tag, plus manual dispatch
- Builds `linux/amd64` image from `docker/Dockerfile`
- Pushes to `ghcr.io/gabrieldeholanda/airyschat` with three tags:
  - `latest` (on default branch)
  - `sha-<commit>` (every build)
  - `develop` (branch name)
- Uses GitHub Actions cache (`type=gha`) for fast incremental builds (~4 min)
- Auth via `GITHUB_TOKEN` — no additional secrets needed

### Triggering a deploy

1. Push code to `develop` (or merge a PR into it)
2. Monitor build: `gh run list --repo gabrieldeholanda/AirysChat --workflow=publish_airyschat_ghcr.yml --limit 3`
3. Once green, pull and redeploy on VPS (see [Deploying a new image](#deploying-a-new-image))

> **Note:** Commits must bypass Husky hooks: `git commit --no-verify` and `git push --no-verify`

---

## Docker Stack Services

### chatwoot_app

Rails web server. Runs DB migrations on every start (idempotent).

```yaml
image: ghcr.io/gabrieldeholanda/airyschat:latest
command: >
  sh -c "bundle exec rails db:migrate && bundle exec rails s -p 3000 -b 0.0.0.0"
resources: 1 CPU / 1024M RAM
```

Exposed via Traefik at `https://chatwoot.airys.com.br`

### chatwoot_sidekiq

Background job processor. Same image as the app, different command.

```yaml
command: bundle exec sidekiq -C config/sidekiq.yml
resources: 1 CPU / 1024M RAM
```

### chatwoot_litellm

LiteLLM proxy that routes LLM calls to OpenAI (and future providers).
The Rails app connects to it internally as `http://chatwoot_litellm:4000`.

```yaml
image: ghcr.io/berriai/litellm:main-latest
config: /root/litellm.yml (mounted read-only)
resources: 1 CPU / 512M RAM
```

Model definitions live in [`config/litellm.yml`](../config/litellm.yml).

### chatwoot_redis

Redis for Sidekiq queues and Action Cable.

```yaml
image: redis:latest
persistence: appendonly AOF
```

### pgvector (external stack)

Postgres with pgvector extension. Managed in a separate stack, accessible via hostname `pgvector` on the `airys` network.

---

## Environment Variables

### Rails App + Sidekiq

| Variable | Value | Notes |
|---|---|---|
| `SECRET_KEY_BASE` | `17f582326cc47d13ec0e4df1dd9fcede` | Keep secret, rotate if exposed |
| `FRONTEND_URL` | `https://chatwoot.airys.com.br` | |
| `INSTALLATION_NAME` | `Airys` | Displayed in UI |
| `DEFAULT_LOCALE` | `pt_BR` | |
| `TZ` | `America/Sao_Paulo` | |
| `POSTGRES_HOST` | `pgvector` | |
| `POSTGRES_DATABASE` | `chatwoot` | |
| `POSTGRES_USERNAME` | `postgres` | |
| `POSTGRES_PASSWORD` | `6a51937a00eaefd3380728ea56731f51` | |
| `REDIS_URL` | `redis://chatwoot_redis:6379` | |
| `ACTIVE_STORAGE_SERVICE` | `local` | Switch to `s3_compatible` for MinIO |
| `LITELLM_BASE_URL` | `http://chatwoot_litellm:4000` | Internal LiteLLM proxy |
| `LITELLM_API_KEY` | `sk-litellm-master-key` | Must match `LITELLM_MASTER_KEY` |
| `GOOGLE_OAUTH_CLIENT_ID` | `532049684192-...` | Google OAuth login |
| `WHATSAPP_CLOUD_API_ENABLED` | `TRUE` | |
| `SMTP_ADDRESS` | `smtp.gmail.com` | |
| `SMTP_PORT` | `587` | |

### LiteLLM Service

| Variable | Value | Notes |
|---|---|---|
| `OPENAI_API_KEY` | `sk-proj-...` | OpenAI provider key |
| `LITELLM_MASTER_KEY` | `sk-litellm-master-key` | Admin key + used as `LITELLM_API_KEY` in app |
| `ANTHROPIC_API_KEY` | _(not set)_ | Add when available |
| `GEMINI_API_KEY` | _(not set)_ | Add when available |

---

## Volumes

All external volumes are pre-created on the VPS:

```bash
docker volume create chatwoot_storage   # Active Storage files
docker volume create chatwoot_public    # Public assets (unused — files baked into image)
docker volume create chatwoot_redis     # Redis AOF persistence
```

> Brand assets (`/brand-assets/airys*.svg`) are committed to `public/brand-assets/` in the repo and baked into the Docker image at build time. No volume mount needed.

---

## Deploying a New Image

After a successful GitHub Actions build:

```bash
# SSH into VPS
ssh root@37.27.190.170

# Pull the new image (credentials already in /root/.docker/config.json)
docker pull ghcr.io/gabrieldeholanda/airyschat:latest

# Redeploy the stack
docker stack deploy -c /root/chatwoot.yaml chatwoot --with-registry-auth

# Verify services are running with new image
docker service ls
docker service ps chatwoot_chatwoot_app --no-trunc | head -3
```

If GHCR auth has expired:

```bash
gh auth token | docker login ghcr.io -u gabrieldeholanda --password-stdin
```

---

## Updating LiteLLM Config

The LiteLLM model list lives in `/root/litellm.yml` on the VPS (also tracked as `config/litellm.yml` in the repo).

To add a new provider:

1. Edit `config/litellm.yml` locally
2. `scp config/litellm.yml root@37.27.190.170:/root/litellm.yml`
3. Add the provider key to `/root/chatwoot.yaml` under `chatwoot_litellm.environment`
4. `docker stack deploy -c /root/chatwoot.yaml chatwoot --with-registry-auth`

Example for Anthropic:
```yaml
# in /root/chatwoot.yaml, chatwoot_litellm environment:
- ANTHROPIC_API_KEY=sk-ant-...
```

---

## Database

- **Host:** `pgvector` container (external Docker Swarm stack)
- **Database:** `chatwoot`
- **User:** `postgres`
- **Extension:** pgvector (for AI embeddings)

### Migrations

Migrations run automatically on every app container start (`bundle exec rails db:migrate`).

### Manual access

```bash
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails db
# or
docker exec -it $(docker ps -q -f name=pgvector) psql -U postgres -d chatwoot
```

### Backups

```bash
docker exec $(docker ps -q -f name=pgvector) \
  pg_dump -U postgres chatwoot \
  > /root/chatwoot_backup_$(date +%Y%m%d_%H%M%S).dump
```

---

## Feature Flags

Some features require explicit activation per account:

```bash
docker exec $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails runner \
  "Account.find(1).enable_features!('whatsapp_template_builder')"
```

Current enabled flags for Account 1:
- `whatsapp_template_builder` — WhatsApp Template Builder + Flows sidebar

---

## Useful Commands

```bash
# View live logs
docker service logs chatwoot_chatwoot_app -f --tail 50
docker service logs chatwoot_chatwoot_sidekiq -f --tail 50
docker service logs chatwoot_chatwoot_litellm -f --tail 20

# Rails console
docker exec -it $(docker ps -q -f name=chatwoot_chatwoot_app) bundle exec rails c

# Restart a single service
docker service update --force chatwoot_chatwoot_sidekiq

# Check all services
docker service ls

# Check health
curl -sI https://chatwoot.airys.com.br
```

---

## Known Issues & Fixes Applied

| Issue | Fix |
|---|---|
| `ActiveRecordQueryTrace` uninitialized in production | Added `if defined?(ActiveRecordQueryTrace)` guard in initializer |
| `BaseNode` uninitialized (Zeitwerk eager load) | All 12 agent node files use `Agent::Nodes::BaseNode` fully qualified |
| `#131009 Components sub_type invalid` on FLOW templates | `TemplateProcessorService` auto-includes `FLOW` button component even with empty `processed_params` |
| Logo broken on login (`/app/public/...` path in DB) | Fixed `InstallationConfig LOGO` to use URL path `/brand-assets/airys.svg`; logo files committed to `public/brand-assets/` |
