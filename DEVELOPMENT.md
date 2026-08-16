# Developing Chatwoot (this repo)

How to run, edit, and ship changes in this repository. Covers the running
Docker containers, the day-to-day development loop, and how dev differs from
production. Read this before you start changing code.

---

## 1. The running containers (what each one does)

From `docker-compose.yaml`. The repo is bind-mounted into `rails`, `sidekiq`,
and `vite` (`./:/app:delegated`), so editing files on the Windows host updates
the containers immediately — there is no copy step.

| Container | Image | Port | Role |
|-----------|-------|------|------|
| `postgres` | pgvector/pg16 | 5432 | Database. Accounts, users, conversations, messages. `restart: always`. |
| `redis` | redis:alpine | 6379 | Cache + job-queue broker + realtime pub/sub. `restart: always`. |
| `rails` | chatwoot-rails:development | 3000 | **The web app.** Puma serves the dashboard AND the API at `http://localhost:3000`. Depends on postgres, redis, vite, mailhog, sidekiq. |
| `sidekiq` | chatwoot-rails:development | — | Background job worker. Runs async jobs queued by rails (emails, webhooks, campaigns, Captain/AI). Same code as rails, no web server. |
| `vite` | chatwoot-vite:development | 3036 | Frontend dev server. Compiles Vue/JS (`app/javascript`) and hot-reloads the browser. Rails proxies asset requests to it. |
| `mailhog` | mailhog/mailhog | 8025 / 1025 | Fake SMTP for dev. Captures all outgoing email so you can inspect it (password resets, invites). UI at `http://localhost:8025`. |
| `base` | chatwoot:development | — | **Build helper, not a runtime service.** Produces the `chatwoot:development` image that rails/sidekiq/vite are built `FROM`. Only touched via `docker compose build base`. |

**Mental model**

```
browser ──▶ rails (:3000) ──▶ postgres, redis
                  │
                  └─ proxies frontend assets ──▶ vite (:3036, HMR)
sidekiq  ◀── jobs queued by rails
mailhog  ◀── captures outgoing email
```

If a feature "does nothing" with no error, it is often a `sidekiq` job — check
`docker compose logs -f sidekiq`.

---

## 2. Development flow (day-to-day)

### Prerequisites (one-time)
- Docker Desktop running on Windows.
- Repo cloned; `.env` present (it is). It holds DB/Redis secrets + `INSTALLATION_NAME`.

### Start the stack
```bash
cd C:\Users\ASUS\Documents\projects\kiraid-logistic\chatwoot
docker compose up -d
# wait ~30–60s, then confirm:
docker compose ps          # rails AND vite must both be "Up"
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/   # expect 200
```

### Log in (dev seed account — already created by `db/seeds.rb`)
```
email:    john@acme.inc
password: Password1!
```
This is the dev seed SuperAdmin. It is the same on every fresh dev install —
do not use it anywhere real.

### The core loop: edit → see the change
- **Frontend** (`app/javascript/**`, `.vue`, `.js`, `.css`): save the file.
  Vite **hot-reloads** the browser automatically (HMR). No refresh, no restart.
  Fastest feedback.
- **Backend normal code** (`app/models`, `app/controllers`, `app/services`,
  `app/lib`, `app/jobs`, `app/views`): Rails auto-reloads (Zeitwerk). Save and
  refresh the browser. No restart.
- **Backend tests**: `docker compose exec rails bundle exec rspec spec/path/to/file_spec.rb`
- **Frontend tests**: `docker compose exec rails pnpm test`
- **Rails console**: `docker compose exec rails bundle exec rails c`
- **Tail logs**: `docker compose logs -f rails` (or `-f vite` / `-f sidekiq`)

### When a save does NOT take effect → you hit a boot-time file
Restart:
```bash
docker compose restart rails          # add sidekiq if jobs are involved
```
Boot-time files (loaded once at startup — need a restart to apply):
- `config/initializers/*`  (everything here loads once)
- `config/application.rb`, `config/environments/*`
- `config/features.yml`   (you flipped several `premium:` flags earlier → restart required)
- `Gemfile` → also run `docker compose exec rails bundle install`, then restart

### Database changes
```bash
docker compose exec rails bundle exec rails db:migrate
docker compose exec rails bundle exec rails db:rollback
docker compose exec rails bundle exec rails db:seed
```

### Git / branching (per `AGENTS.md`)
- Base branch is `develop`. Work on a feature branch off it.
- Commits: Conventional Commits (`feat:`, `fix:`, …).
- Do **not** commit the Docker-only `config/vite.json` / `vite.config.ts`
  changes if you also run Chatwoot natively elsewhere — they are Docker-specific.

---

## 3. Production flow (how this repo builds & deploys)

The same `docker/Dockerfile` builds in two modes:

### A. The image (multi-stage, `docker/Dockerfile`)
- Build arg `RAILS_ENV` defaults to `production`.
- In production mode it runs `bundle exec rake assets:precompile` — compiles the
  Vue/JS frontend into static files under `public/` and strips dev/test gems and
  `node_modules`.
- **No vite dev server, no HMR** in prod — assets are prebuilt static files
  served by Puma directly. (So the Docker-only vite networking fixes do not
  matter in production.)

### B. Deploy target (`deployment/chatwoot/` — systemd + nginx, single server)
Contains: `chatwoot-web.service`, `chatwoot-worker.service` (systemd units),
`nginx_chatwoot.conf` (reverse proxy to Puma), and `setup_18.04.sh` /
`setup_20.04.sh`.
- Classic single-server deploy: nginx → Puma (rails), systemd keeps web +
  worker (sidekiq) alive.
- **No Helm / Kubernetes / Capistrano** in this repo. For k8s/cloud, you would
  build the prod image, push to a registry, and write your own manifests. The
  image is cloud-agnostic.

### Dev vs Prod at a glance
| Aspect | Dev (`docker compose`) | Prod (`Dockerfile` + systemd) |
|--------|------------------------|-------------------------------|
| Assets | vite dev server, HMR | precompiled static (`rake assets:precompile`) |
| vite container | yes (3036) | no |
| Hot reload | yes | no |
| Gems | all (incl. dev/test) | production only |
| Mail | mailhog (captured) | real SMTP |
| Run via | `docker compose up -d` | systemd + nginx (or your k8s) |

**Never develop against the production image** — no HMR, no dev tools,
precompiled assets.

**Which compose file runs when?**
- `docker compose up` / `docker compose build` / `docker compose ps` → uses
  **`docker-compose.yaml`** automatically. This is the **dev** setup.
- `docker-compose.production.yaml` → **NOT used unless you pass `-f`**.
  Compose only picks it up when you explicitly request it.

So if you want live Vite HMR, bind-mounted source edits, mailhog, etc., use
the dev file. Example commands:

```bash
# DEV (default, live reload)
docker compose up -d            # reads docker-compose.yaml
docker compose build rails vite # rebuilds the dev images

# PROD image (prebuilt static assets, no vite container)
docker compose -f docker-compose.production.yaml up -d --build
```

If you ever ran the prod compose, it won’t pick up local JS/Vue edits because
it doesn’t bind-mount `app/javascript/` and it doesn’t run a Vite dev server.

If you want to rebuild prod assets inside the dev stack:

```bash
docker compose exec rails bundle exec rake assets:precompile RAILS_ENV=production
```

---

## 4. Where things live & conventions

- **Ruby backend**: `app/` (models, controllers, services, jobs, views),
  `lib/`, `config/`
- **Frontend**: `app/javascript/` (Vue 3; message bubbles in `components-next/`
  per `AGENTS.md`)
- **Feature flags**: `config/features.yml` (boot-time → restart to apply)
- **Routes**: `config/routes.rb`
- **Env**: `.env` (gitignored — do not commit secrets)

### Custom code already in this repo
- `custom_captain_llm_server/` — a separate Python LLM backend you wrote. It is
  **not** wired into the compose stack (no service for it, not referenced by the
  repo yet). If Captain should use it, that is future wiring (point Chatwoot's
  LLM config at it). Right now it is just a folder.
- `config/features.yml` edits — several `premium: true → false` flags flipped
  (e.g. `disable_branding`, `audit_logs`, `sla`). Need a `rails` restart.

### Conventions (from `AGENTS.md`)
- Ruby: RuboCop, 150-char lines. Vue: ESLint (Airbnb + Vue 3), Composition API
  with `<script setup>`.
- Styling: **Tailwind only** — no custom CSS, no scoped CSS, no inline styles.
- No bare strings in templates → use i18n (`en.json` frontend / `en.yml` backend).
- Enterprise overlay lives in `enterprise/` — if you touch core logic that may
  need paid features, check there too.

---

## 5. Troubleshooting ladder

1. **Container missing from `docker compose ps`** → `docker compose up -d`.
2. **rails/vite exit immediately, never appear** → CRLF entrypoint bug (Windows
   `core.autocrlf`). Fix: renormalize `.sh`/`.bin` to LF + rebuild images.
   (Repo now has `.gitattributes` pinning LF for these.)
3. **vite "Up" but nothing on 3036** → entrypoint `pnpm install --force` hanging
   on a flaky network. Install once; the `node_modules` volume persists.
4. **rails → vite returns 000/403** (not 404) → host binding / `allowedHosts`
   wrong. Needs `host: 0.0.0.0` + `allowedHosts: true`.
5. **`GET /` hangs** → Rails inline `vite build` loop. Must have
   `autoBuild: false` in `config/vite.json`.
6. **First hit slow (30–90s)** → normal dev boot (lazy loading + Vite proxy).
   One `200` is enough to confirm it works.

### Quick health check
```bash
curl -s -m 30 -o /dev/null -w "GET / -> %{http_code}\n" http://127.0.0.1:3000/
curl -s -m 30 -o /dev/null -w "GET /api -> %{http_code}\n" http://127.0.0.1:3000/api
# both 200 → open http://localhost:3000/
```

---

## 6. Daily command cheat sheet
```bash
docker compose ps                     # health
docker compose logs -f rails          # follow app logs
docker compose restart rails          # apply boot-time changes
docker compose exec rails bundle exec rails c        # console
docker compose exec rails bundle exec rails db:migrate
docker compose down                   # full stop (volumes persist)
```

---

*Companion doc: see `README.md` for the Windows/CRLF gotchas and the
`docker compose exec` ordering notes.*
