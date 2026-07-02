# RAILS_ENV=test would have run specs against the live Neon dev database

- **Date**: 2026-07-02
- **Phase**: Phase 0
- **Area**: docker / db

## Symptom

Not a crash — a hazard found during test-DB setup. `config/database.yml` uses
the same `POSTGRES_DATABASE` env var for every environment:

```text
test:
  <<: *default
  database: <%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_test') %>
```

`.env` sets `POSTGRES_DATABASE` to the dev database on Neon, so any
`RAILS_ENV=test` command with `.env` loaded (which `docker compose run rails`
always does via `env_file`) would have pointed the spec suite — including
DatabaseCleaner truncation — at the live dev data.

## Root cause

Upstream `database.yml` assumes per-environment env files; this fork uses one
shared `.env` with an external (Neon) database, so the test env inherited the
dev database name, host, and credentials.

## Fix

Added fork-local `docker-compose.rspec.yaml` defining tmpfs-backed
`postgres-test` (`pgvector/pgvector:pg16` — schema needs the `vector`
extension) and `redis-test` containers, plus a `test` service that
hard-overrides `POSTGRES_HOST/PORT/DATABASE/USERNAME/PASSWORD/SSLMODE` and
`REDIS_URL` after `env_file: .env`. Did **not** reuse the name
`docker-compose.test.yaml` — that upstream-tracked file is a production-style
deployment compose, not a test runner.

Rule going forward: never run `RAILS_ENV=test` through the plain `rails`
compose service; always use the `test` service from `docker-compose.rspec.yaml`.

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rails db:prepare
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/lib/webhooks/trigger_spec.rb
# => 20 examples, 0 failures
```

## Notes / related

Benign container noise seen during runs (no action needed): git "dubious
ownership in repository at '/app'" warning, reline/fiddle Ruby 3.5 deprecation
warning, `Rails.application.secrets` deprecation.
