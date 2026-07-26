# REDIS_URL pointed at a compose service the fork had deleted

- **Date**: 2026-07-27
- **Phase**: Phase 0 (dev environment)
- **Area**: docker

## Symptom

`.env` shipped the upstream default:

```text
REDIS_URL=redis://redis:6379
```

but `docker compose config --services` listed only `base`, `rails`, `sidekiq`,
`vite`. There is no `redis` service, so the hostname does not resolve on the
compose network and sidekiq dies on connect:

```text
Error connecting to Redis on redis:6379 (SocketError)
getaddrinfo: Name or service not known
```

## Root cause

Fork commit `63b23b2a6` ("Added custom SaaS provisioning") rewrote
`docker-compose.yaml` for an external-infra dev stack and **deleted the
`postgres`, `redis` and `mailhog` services** — the intent recorded in
`docs/fork/UPSTREAM_DIFF.md:191-215` was Neon for Postgres and Upstash for Redis.
`.env` was never updated to match: `REDIS_URL` kept pointing at the removed
local service.

So the dev stack was in a split state — Postgres externalised, Redis nominally
externalised but still addressed by its old local hostname.

## Fix

Postgres stays external (Neon). Redis is brought back as a **local** container,
which is what `REDIS_URL=redis://redis:6379` already expects — no `.env` change
needed for it. Restored in `docker-compose.yaml`:

- `redis` (`redis:alpine`) with a `redis-cli ping` healthcheck and a named
  `redis` volume.
- `mailhog` for dev SMTP — `.env` already had `SMTP_PORT=1025`; `SMTP_ADDRESS`
  was blank and is now `mailhog`. Web UI on `:8025`.

Both `rails` and `sidekiq` now gate on Redis:

```yaml
depends_on:
  redis:
    condition: service_healthy
```

The `sidekiq` gate is the important one. `sidekiq` declares **no `entrypoint:`**,
and neither Dockerfile defines one, so it bypasses `docker/entrypoints/rails.sh`
entirely — it gets no `pg_isready` wait and there is no Redis wait anywhere in
the boot path. Without the healthcheck gate it starts ahead of Redis and
crash-loops.

The `redis` command keeps upstream's `--requirepass "$$REDIS_PASSWORD"` form so
the password hook survives. Note the `$$` — that escapes to a literal `$` so the
variable is expanded **inside the container** from `env_file: .env`, rather than
being interpolated by Compose at parse time. `REDIS_PASSWORD` is currently empty,
which Redis treats as "no password", matching the credential-less `REDIS_URL`.

## Verification

```sh
docker compose up -d redis mailhog
docker compose ps redis          # => Up (healthy)
docker compose exec -T redis redis-cli ping
# => PONG
```

Sidekiq should reach Redis without a restart loop:

```sh
docker compose logs sidekiq | head -20
```

## Notes / related

- If Redis is later moved to Upstash, change `REDIS_URL` to the `rediss://`
  endpoint and drop the local service + both `depends_on` gates — do not leave
  the two configurations half-applied, which is what caused this.
- Companion entry: [2026-07-27 — Full Neon connection URL pasted into POSTGRES_DATABASE](./2026-07-27-neon-url-pasted-into-postgres-database-var.md)
- `docs/fork/UPSTREAM_DIFF.md:191-215` documents the compose rewrite and should
  be kept in sync with this change.
