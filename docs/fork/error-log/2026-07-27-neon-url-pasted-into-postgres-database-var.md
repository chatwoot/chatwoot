# Full Neon connection URL pasted into POSTGRES_DATABASE

- **Date**: 2026-07-27
- **Phase**: Phase 0 (dev environment)
- **Area**: db / docker

## Symptom

The dev stack could not reach Postgres at all. `docker/entrypoints/rails.sh:14-19`
hung forever in its unbounded `pg_isready` loop:

```text
Waiting for postgres to start
Waiting for postgres to start
Waiting for postgres to start
```

`docker compose ps` still showed every container `Up`, so the stack looked
healthy while nothing could actually connect.

## Root cause

The whole Neon connection URL had been pasted into `POSTGRES_DATABASE`:

```text
POSTGRES_DATABASE=postgresql://<user>:<redacted>@<neon-host>/mesh-crm?sslmode=require&channel_binding=require
POSTGRES_HOST=postgres        # still the .env.example default
POSTGRES_USERNAME=postgres    # still the .env.example default
```

`config/database.yml:22` consumes `POSTGRES_DATABASE` as a bare **database
name**, not a URL, and there is no `url:` key anywhere in that file. So the
Neon host, user and password never reached Rails — it kept dialling the
long-deleted local `postgres` service (see the companion entry below) with a
database literally named `postgresql://...`.

Second, latent break: `POSTGRES_SSLMODE` was unset, so `config/database.yml:11`
fell through to its `disable` default. Neon refuses non-TLS connections, so even
a correct host/user/password would have been rejected.

## Fix

Split the URL into the discrete vars `config/database.yml` actually reads, and
set the SSL mode hook:

```text
POSTGRES_HOST=<neon-pooler-host>
POSTGRES_PORT=5432
POSTGRES_USERNAME=<neon-role>
POSTGRES_PASSWORD=<redacted>
POSTGRES_DATABASE=mesh-crm
POSTGRES_SSLMODE=require
```

**Do not "simplify" this back into a single `DATABASE_URL`.** Rails 7.1 merges a
`DATABASE_URL` over the YAML config, so it would work for dev — but
`docker-compose.rspec.yaml:49-54` isolates the test stack by overriding the
discrete `POSTGRES_*` vars and does **not** override `DATABASE_URL`. Setting it
would punch through that guard and point `RAILS_ENV=test` at the live Neon
database, where DatabaseCleaner truncates. That is exactly the incident in
[2026-07-02 — RAILS_ENV=test would have hit the live Neon dev DB](./2026-07-02-test-env-pointed-at-neon-dev-db.md).

Consequence of using discrete vars: `channel_binding=require` has no ENV hook
(there is no `channel_binding:` key in `config/database.yml`). It is optional for
Neon; `sslmode=require` is the load-bearing one. If it is ever needed, set the
libpq env var `PGCHANNELBINDING=require` on the container rather than
introducing `DATABASE_URL`.

## Verification

Connectivity and TLS, without booting the app:

```sh
docker run --rm postgres:16-alpine \
  pg_isready -h "$POSTGRES_HOST" -p 5432 -U "$POSTGRES_USERNAME"
# => <host>:5432 - accepting connections
```

Then through Rails itself:

```sh
docker compose run --rm rails bundle exec rails runner "puts Account.count"
```

## Notes / related

- Neon reports `PostgreSQL 18.4`; all five extensions `db/schema.rb:15-19`
  requires (`pg_stat_statements`, `pg_trgm`, `pgcrypto`, `plpgsql`, `vector`)
  are available to the `neondb_owner` role, so `CREATE EXTENSION` at schema-load
  time needs no superuser.
- First schema load should raise the statement timeout — `config/database.yml:18`
  defaults `POSTGRES_STATEMENT_TIMEOUT` to `14s`, which a cold Neon start plus a
  full `db:chatwoot_prepare` can exceed. Upstream's own runbook uses
  `POSTGRES_STATEMENT_TIMEOUT=600s` (`deployment/setup_20.04.sh:411`).
- Companion entry: [2026-07-27 — REDIS_URL pointed at a compose service the fork had deleted](./2026-07-27-redis-service-missing-from-compose.md)
