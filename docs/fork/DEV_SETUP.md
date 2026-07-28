# Dev Setup — from a fresh clone to a running stack

Everything needed to go from `git clone` to a working dashboard at
<http://localhost:3000>. Every command here was run and verified on
2026-07-27; the verification outputs quoted are real, not illustrative.

If something fails, check [error-log/](./error-log/README.md) **first** —
`rg -i "<error snippet>" docs/fork/error-log/` — most first-run failures are
already documented there with a fix.

---

## 0. What you need

| Requirement | Notes |
| --- | --- |
| Docker + Docker Compose v2 | Verified on Docker 29.6.2 / Compose v5.3.1 |
| A Postgres database | **External.** Neon is what this fork uses. Not run by compose. |
| ~10 GB disk | The dev image is ~5 GB; there are three tags. |
| ~25 min for the first build | Subsequent builds are cached and take seconds. |

**No local Ruby, Node, or Postgres client is required or wanted.** Ruby is not
installed on the dev machine this fork is maintained on. Every Ruby/Rails/RSpec
command runs inside a container — see [Everyday commands](#6-everyday-commands).

### What runs where

| Service | Where | Port | Notes |
| --- | --- | --- | --- |
| `rails` | compose | 3000 | The dashboard + API |
| `vite` | compose | 3036 | Frontend dev server |
| `sidekiq` | compose | — | Background jobs |
| `redis` | **compose (local)** | 6379 | Broker + cache |
| `mailhog` | **compose (local)** | 1025 / 8025 | Dev SMTP sink, UI on 8025 |
| Postgres | **external (Neon)** | 5432 | Configured via `POSTGRES_*` in `.env` |

Postgres is the only piece not in the stack. Everything else comes up with one
`docker compose up`.

> Older docs (including `IMPLEMENTATION_PLAN.md` Phase 0) describe Redis as
> external on Upstash. That is no longer true — Redis is a local compose
> service. See
> [error-log 2026-07-27](./error-log/2026-07-27-redis-service-missing-from-compose.md)
> for why it moved back.

---

## 1. Configure `.env`

```sh
cp .env.example .env
```

`.env` is gitignored and **must never be committed**. So are `.env.bak.*`
backups.

### The Postgres block — the one that bites everyone

`.env.example` ships with local-Docker defaults that no longer match this
stack. Set these six keys:

```dotenv
POSTGRES_HOST=<your-neon-pooler-host>     # e.g. ep-xxx-pooler.<region>.aws.neon.tech
POSTGRES_PORT=5432
POSTGRES_USERNAME=<your-neon-role>        # e.g. neondb_owner
POSTGRES_PASSWORD=<your-neon-password>
POSTGRES_DATABASE=<bare database name>    # e.g. mesh-crm  — NOT a URL
POSTGRES_SSLMODE=require                  # Neon rejects non-TLS connections
```

Two traps, both of which have cost real debugging time:

1. **`POSTGRES_DATABASE` is a bare database name, not a connection URL.**
   Neon's dashboard hands you `postgresql://user:pass@host/db?sslmode=require`.
   Pasting that whole string in is wrong — `config/database.yml:22` uses this
   value as a database name. You must split it across the keys above.
2. **`POSTGRES_SSLMODE` must be set explicitly.** `config/database.yml:11`
   defaults it to `disable`, and Neon refuses non-TLS connections. Without it
   you get a connection failure even with everything else correct.

Full write-up:
[error-log 2026-07-27](./error-log/2026-07-27-neon-url-pasted-into-postgres-database-var.md).

### Do NOT use `DATABASE_URL`

It is tempting — Rails 7.1 honours it and it is one line instead of six. **Do
not.** `docker-compose.rspec.yaml:49-54` isolates the test database by
overriding the discrete `POSTGRES_*` vars, and it does **not** override
`DATABASE_URL`. Setting it makes `RAILS_ENV=test` connect to your live
development database, where DatabaseCleaner truncates every table. See
[error-log 2026-07-02](./error-log/2026-07-02-test-env-pointed-at-neon-dev-db.md).

Consequence: `channel_binding=require` has no env hook (there is no
`channel_binding:` key in `config/database.yml`). It is optional for Neon —
`sslmode=require` is the load-bearing one. If you ever truly need it, set the
libpq variable `PGCHANNELBINDING=require` on the container rather than
introducing `DATABASE_URL`.

### Other keys worth setting

```dotenv
REDIS_URL=redis://redis:6379    # 'redis' is the compose service name — leave as-is
REDIS_PASSWORD=                 # empty = no auth, matches the URL above
FRONTEND_URL=http://localhost:3000
SMTP_ADDRESS=mailhog
SMTP_PORT=1025
```

`FRONTEND_URL` must be a **routable host**. `.env.example` ships
`http://0.0.0.0:3000`; `0.0.0.0` is a bind address, and this value feeds
`OmniAuth.config.full_host` (`config/initializers/omniauth.rb:3`) and
`action_mailer.default_url_options` (`config/initializers/mailer.rb:7`). Leave
it as `0.0.0.0` and OAuth callbacks plus every emailed link — password resets,
agent invites — are broken.

### Sanity-check connectivity before building

Worth 20 seconds, saves a 25-minute build against a database you can't reach:

```sh
docker run --rm postgres:16-alpine \
  pg_isready -h "<POSTGRES_HOST>" -p 5432 -U "<POSTGRES_USERNAME>"
# expected: <host>:5432 - accepting connections
```

The stack needs this to pass, because `docker/entrypoints/rails.sh:14-19` blocks
on exactly this check **in a loop with no timeout** — a wrong host means the
rails container hangs forever printing "Waiting for postgres" rather than
failing.

---

## 2. Build the images — **base first, on its own**

```sh
docker compose build base      # ~20-25 min on a cold cache. Must finish first.
docker compose build rails vite
```

**Do not run `docker compose build base rails vite` in one command on a fresh
clone.** Compose builds targets in parallel, so `rails` and `vite` try to
resolve their base image before `base` has produced it, and the build dies with:

```text
target vite: failed to solve: mesh-crm:development:
pull access denied, repository does not exist or may require authorization
```

This only bites on a fresh clone. Once `mesh-crm:development` exists locally,
the combined command works — which is why the older instruction in
`IMPLEMENTATION_PLAN.md` looked fine for years.

### The images are fork-owned

| Image | Built from |
| --- | --- |
| `mesh-crm:development` | `docker/Dockerfile` (base) |
| `mesh-crm-rails:development` | `docker/dockerfiles/rails.Dockerfile` |
| `mesh-crm-vite:development` | `docker/dockerfiles/vite.Dockerfile` |

They are **not** upstream's published `chatwoot:*` images. The build context is
this repo, so the `custom/` overlay is baked in. The two child Dockerfiles use
`ARG BASE_IMAGE=chatwoot:development` + `FROM ${BASE_IMAGE}`, defaulting to
upstream's original value so the upstream build is unaffected; compose passes
`BASE_IMAGE: mesh-crm:development`.

> **Rebuild whenever `Gemfile.lock` or `package.json` moves.** The base image
> bakes gems into `/gems`. If the lockfile is newer than the image, `vite` and
> `sidekiq` die on startup with
> `Could not find <gem> ... (Bundler::GemNotFound)`. `rails` deceptively
> survives, because `docker/entrypoints/rails.sh:24` runs `bundle install` on
> every boot — so **a healthy `rails` container is not evidence the image is
> current.** See
> [error-log 2026-07-10](./error-log/2026-07-10-stale-containers-404-after-image-retag.md).

---

## 3. Load the database schema

Nothing in the boot path runs migrations — not the entrypoints, not compose. On
a fresh database you must do this explicitly, or every page returns a 500
`ActiveRecord::PendingMigrationError` while `docker compose ps` cheerfully shows
everything `Up`.

```sh
docker compose up -d redis
docker compose run --rm --no-deps \
  -e POSTGRES_STATEMENT_TIMEOUT=600s \
  rails bundle exec rails db:chatwoot_prepare
```

Notes:

- **`db:chatwoot_prepare`**, not `db:prepare`. It is the repo's own task
  (`lib/tasks/db_enhancements.rake:17-33`) and handles the "database already
  exists but is empty" case that Neon gives you. It loads the schema, seeds
  once, then migrates.
- **`POSTGRES_STATEMENT_TIMEOUT=600s` is required.**
  `config/database.yml:18` defaults to `14s`, which a cold Neon start will
  exceed. Upstream's own runbook does the same
  (`deployment/setup_20.04.sh:411`).
- Redis must be up first — seeding touches Sidekiq.
- Expect this to take several minutes against a remote database. It is
  network-latency bound, not CPU bound.
- **Want no sample data?** Use `db:schema:load` instead, and skip the seeds
  entirely.

On success you should see roughly:

```text
99 tables, 159 migrations, 103 installation_configs, 2 accounts, 1 user
```

---

## 4. Start the stack

```sh
docker compose up -d
```

One stack, `mesh-crm` (pinned via `name:` in `docker-compose.yaml`), five
services. `base` does not start — it sits behind the `build-only` profile by
design.

**After any rebuild or re-tag, recreate rather than restart:**

```sh
docker compose up -d --force-recreate
```

Containers pin an image ID at creation time, so a re-tagged image is ignored by
`docker start` / `docker compose restart` and you keep running the old code —
or hit `No such image` 404s. See
[error-log 2026-07-10](./error-log/2026-07-10-stale-containers-404-after-image-retag.md).

`vite` takes ~60s to become ready because `docker/entrypoints/vite.sh:8` runs
`pnpm install --force` on every boot. That is expected, not a hang.

---

## 5. Verify it actually works

`docker compose ps` showing `Up` is **not** verification — that is precisely how
both the pending-migration and stale-gem failures disguise themselves. Check
the layers that matter:

```sh
# 1. The app answers, and its own health view agrees
curl -s http://localhost:3000/api
# {"version":"4.16.1","queue_services":"ok","data_services":"ok"}
```

That single response is the best smoke test in the repo: `queue_services: ok`
proves Redis/Sidekiq, `data_services: ok` proves Postgres.

> **`data_services: failing` is usually a stale pooled connection, not a broken
> setup.** `app/controllers/api_controller.rb:21` implements the check as
> `ActiveRecord::Base.connection.active?` — a liveness probe on a *pooled*
> connection that returns false for a dead socket **without reconnecting**.
> Neon's serverless compute auto-suspends when idle and drops those sockets, so
> after an idle period — or for several minutes after
> `up -d --force-recreate` — the endpoint can report `failing` while the
> database is perfectly healthy.
>
> The tell: a fresh process connects fine even while `/api` says `failing`.
>
> ```sh
> docker compose exec -T rails bundle exec rails runner \
>   'puts ActiveRecord::Base.connection.execute("select 1").first'
> ```
>
> **Fix: send real traffic.** Load <http://localhost:3000/app/login> once; the
> query re-establishes the connection and `/api` flips to `ok` and stays there.
> Polling `/api` alone may *not* clear it, because `.active?` never reconnects.
> Confirm the database independently with:
>
> ```sh
> docker run --rm -e PGPASSWORD="<pw>" -e PGSSLMODE=require postgres:16-alpine \
>   psql -h "<host>" -U "<user>" -d "<db>" -Atc "select 1;"
> ```
>
> If that returns `1`, the database is fine. Only treat it as a real failure if
> `data_services` stays `failing` once Neon is warm.

Also expect the **first page load to take ~10s** in development — Rails is
compiling assets on demand via Vite. Subsequent loads are fast. This is not a
symptom of a problem.

```sh
# 2. The dashboard renders
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/app/login   # 200

# 3. Vite is serving assets (not just listening)
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3036/vite-dev/@vite/client   # 200

# 4. Sidekiq is processing, not just running
docker compose logs sidekiq --tail 20    # expect "INFO: done" job lines

# 5. The fork overlay is live, not merely present on disk
docker compose exec -T rails bundle exec rails runner \
  'puts Account.ancestors.map(&:to_s).grep(/Custom/).first(3)'
# Custom::Account::PlanUsageAndLimits
# Custom::Account
```

Check 5 is the one that distinguishes "running Chatwoot" from "running *this
fork*". If no `Custom::` modules appear in the ancestor chain, the overlay is
not being injected and quota enforcement is silently absent.

### Log in

| | |
| --- | --- |
| URL | <http://localhost:3000> |
| Email | `john@acme.inc` |
| Password | `Password1!` |
| Role | SuperAdmin (`/super_admin` console) |

From `db/seeds.rb:28`. Change or delete this user before any deployment.

Mailhog UI (every outbound dev email lands here): <http://localhost:8025>

---

## 6. Everyday commands

All Ruby runs in containers — there is no local Ruby.

```sh
# Rails / rake / rubocop
docker compose run --rm rails bundle exec rails <cmd>
docker compose run --rm rails bundle exec rubocop -a

# Frontend
docker compose run --rm vite pnpm eslint
docker compose run --rm vite pnpm test

# Logs
docker compose logs -f rails
docker compose ps
```

### RSpec — always through the isolated test stack

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml \
  run --rm test bundle exec rspec spec/custom/...
```

**Never run `RAILS_ENV=test` through the plain `rails` service.** It inherits
`.env`, so DatabaseCleaner would truncate your live development database.

First-time test DB init (schema only — **never** `db:prepare`, which seeds and
breaks `installation_config` specs):

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml \
  run --rm test bundle exec rails db:create db:schema:load
```

The test Postgres is tmpfs-backed, so re-run that after the container is
recreated.

### Migrations

```sh
docker compose exec rails bundle exec rails db:migrate
```

Run it through the `rails` **service**, which sets
`ANNOTATERB_SKIP_ON_DB_TASKS=1`. Without that guard, annotaterb re-annotates
every drifted model and spills diffs into OSS/enterprise files the fork must not
touch. See
[error-log 2026-07-10](./error-log/2026-07-10-db-migrate-annotation-spill-into-oss-files.md).

---

## 7. Troubleshooting quick reference

| Symptom | Cause | Fix |
| --- | --- | --- |
| Rails container prints `Waiting for postgres` forever | Wrong `POSTGRES_HOST`, or `pg_isready` can't reach it. The loop has no timeout. | Fix the host; verify with the `pg_isready` command in §1 |
| Connection refused / SSL error from Neon | `POSTGRES_SSLMODE` unset → defaults to `disable` | `POSTGRES_SSLMODE=require` |
| Database name looks like a URL in errors | Whole Neon URL pasted into `POSTGRES_DATABASE` | Split it into the six keys in §1 |
| `vite`/`sidekiq` exit with `Could not find <gem> (Bundler::GemNotFound)` | Base image older than `Gemfile.lock`. `rails` hides it via its entrypoint `bundle install`. | Rebuild base (§2), then `up -d --force-recreate` |
| Build fails: `pull access denied ... mesh-crm:development` | Built `base rails vite` together on a fresh clone | Build `base` alone first (§2) |
| Every page 500s with `PendingMigrationError` while containers show `Up` | Schema never loaded / migrations pending | §3, or `docker compose exec rails bundle exec rails db:migrate` |
| Assets 404; `:3036` resets connections | Vite bound to container-localhost | `VITE_RUBY_HOST=0.0.0.0` (already set); apply via `up`, **not** `restart` |
| Containers dead with `No such image` after a rebuild | Containers pin image IDs | `docker compose up -d --force-recreate` |
| Password-reset / invite links point at `0.0.0.0` | `FRONTEND_URL` is a bind address | `FRONTEND_URL=http://localhost:3000` |
| Specs wipe your dev data | `RAILS_ENV=test` through the `rails` service, or `DATABASE_URL` set | Use the rspec stack (§6); never set `DATABASE_URL` |
| `data_services: failing` after idle, or for minutes after `--force-recreate` | Stale pooled connection — Neon suspended and dropped the socket; `.active?` doesn't reconnect | Load a real page once (`/app/login`); it re-establishes and stays `ok`. See §5. |
| Changed Neon region/host in `.env` but the app still uses the old one | Compose injects env at container **creation** | `docker compose up -d --force-recreate` — `restart` will not pick it up. Verify with `docker compose exec rails printenv POSTGRES_HOST` |
| First page load takes ~10s | Dev-mode on-demand asset compilation | Expected; subsequent loads are fast |
| `db/schema.rb` shows as modified after a db task, with no migration added | Neon runs PG18; the committed schema was dumped from PG16, so index order and `WHERE` parens differ | `git checkout -- db/schema.rb`. Never commit this churn — see [error-log 2026-07-27](./error-log/2026-07-27-schema-rb-churn-from-neon-postgres-18.md) |

---

## 8. Fork ground rules

Before changing code, read [ARCHITECTURE.md](./ARCHITECTURE.md) and the ground
rules in [README.md](./README.md). The short version:

1. **Never edit `app/`, `lib/`, or `enterprise/` when an overlay works.** Fork
   code lives in `custom/`, injected via `prepend_mod_with` /
   `include_mod_with`.
2. **No local Ruby** — everything through Docker.
3. **Every fixed error gets an entry in
   [error-log/](./error-log/README.md)**, using `TEMPLATE.md`, when the fix
   lands. This file exists because that rule was followed.
4. **Public contracts are frozen** — route paths, webhook event names and
   payloads, `X-Chatwoot-*` headers, and existing response shapes may only be
   extended additively.
5. **Never commit `.env`** or paste its values into docs, logs, or commits.

Fork specs live in `spec/custom/`, mirroring the OSS layout.
