# Seeded test DB broke installation_config specs

- **Date**: 2026-07-02
- **Phase**: Phase 2
- **Area**: db / ci

## Symptom

Enterprise account specs failed on a fresh test stack:

```text
ActiveRecord::RecordNotUnique: PG::UniqueViolation: duplicate key value
violates unique constraint "index_installation_configs_on_name"
DETAIL: Key (name)=(CAPTAIN_CLOUD_PLAN_LIMITS) already exists.

Account subscribed_features when plan_features is blank returns an empty array
  expected: nil / got: []
```

## Root cause

The test database was initialized with `rails db:prepare`
(error-log entry [2026-07-02 — test env pointed at Neon](./2026-07-02-test-env-pointed-at-neon-dev-db.md)),
which runs `db:seed` on first create. Seeds insert `installation_configs`
rows; DatabaseCleaner does not remove pre-suite data for that table, so specs
that `create(:installation_config, name: ...)` hit the unique index, and
specs asserting "no config present" saw seeded values.

## Fix

Initialize the spec database schema-only — never seed it:

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rails db:drop db:create db:schema:load
```

(`db:prepare` is fine for the dev DB, wrong for the spec DB.)

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/custom spec/enterprise/models/account_spec.rb ...
# => 275 examples, 0 failures
```

## Notes / related

The postgres-test container is tmpfs-backed, so the schema load must be
re-run whenever the container is recreated (e.g. after `docker compose down`).
