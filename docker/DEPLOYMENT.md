# Zero-downtime deploys (Docker Compose, single host)

`docker-compose.production.yaml` runs the stack as:

| Service   | Role                                                        | Stop behaviour on SIGTERM                                |
|-----------|-------------------------------------------------------------|----------------------------------------------------------|
| `migrate` | One-shot `rails db:chatwoot_prepare`                        | Exits when done. `rails`/`sidekiq` wait for exit code 0. |
| `rails`   | Puma web replicas (`WEB_REPLICAS`, default 1)               | Stops accepting, finishes in-flight requests, then exits. |
| `sidekiq` | Worker replicas (`WORKER_REPLICAS`, default 1)              | Stops fetching, finishes running jobs, then exits.       |
| `proxy`   | nginx on `127.0.0.1:3000`, load-balances across `rails`     | n/a                                                      |
| `postgres`, `redis` | Unchanged                                          | n/a                                                      |

Health:

- `rails` is healthy when `GET /health/ready` returns 200, i.e. Postgres and Redis are reachable.
- `sidekiq` is healthy when its `sidekiq_alive` endpoint (port 7433) responds.
- `GET /health` is still a plain liveness check.

## Rolling deploy

```sh
docker/deploy.sh
```

For each replica the script starts a replacement, waits for it to become healthy, then stops the old
replica with SIGTERM and lets it drain. Order of operations:

1. `docker compose pull` (skip with `DEPLOY_PULL=0`).
2. `docker compose run --rm migrate`. **If this fails, the deploy stops and nothing running is touched.**
3. Roll `rails` one replica at a time, then `sidekiq`.
4. Recreate `proxy` if its configuration changed.

If a replacement never becomes healthy, it is removed and the deploy fails, while the old replicas keep serving.

Run it with `COMPOSE_FILE` set if you use a different compose file. A plain `docker compose up -d` still
works and runs migrations first, but it replaces all containers at once, so it does not give zero downtime.

## Tuning

| Variable                   | Default | Purpose                                                                        |
|----------------------------|---------|--------------------------------------------------------------------------------|
| `WEB_REPLICAS`             | `1`     | Number of Rails/Puma containers. With 1, a rolling deploy still surges to 2 briefly. |
| `WORKER_REPLICAS`          | `1`     | Number of Sidekiq containers.                                                  |
| `WEB_STOP_GRACE_PERIOD`    | `60s`   | How long a web container may take to drain before Docker sends SIGKILL.       |
| `WORKER_STOP_GRACE_PERIOD` | `150s`  | Same, for workers. Must be longer than `SIDEKIQ_SHUTDOWN_TIMEOUT`.            |
| `SIDEKIQ_SHUTDOWN_TIMEOUT` | `120`   | Seconds a worker waits for running jobs on SIGTERM. Jobs still running after this are pushed back to their queue and run again, so raise it for long jobs. |

## Rollback

Deploy the previous image tag. Migrations do not run backwards, so the previous release must work against the
current schema:

```sh
CHATWOOT_IMAGE=chatwoot/chatwoot:<previous-tag> docker/deploy.sh
```

Pin a version tag in production rather than `latest-ce`, so you always know what you are rolling back to.

## Writing migrations for zero-downtime deploys

During a rolling deploy, old and new code run against the same schema at the same time. Each migration
must therefore keep the previous release working:

- Add columns as nullable or with a default, and add indexes concurrently.
- Rename or drop columns in a later release, after no running code reads them.
- Do not change a column's meaning in place.
