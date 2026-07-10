# Vite dev server bound to container-localhost — assets 404 in the browser

- **Date**: 2026-07-10
- **Phase**: dev environment
- **Area**: docker / frontend

## Symptom

`docker compose ps` showed `vite` Up with `0.0.0.0:3036->3036/tcp` published,
and the server answered **inside** the container — but every request from the
host got connection-reset:

```text
$ curl -s -o /dev/null -w '%{http_code}' http://localhost:3036/vite-dev/@vite/client
000        # curl exit 56, connection reset
$ docker compose exec vite wget -qO /dev/null http://localhost:3036/vite-dev/@vite/client
# -> 200 inside the container
```

So the dashboard loaded its HTML from Rails (:3000) but every Vite asset the
browser requested failed — surfacing as broken pages / 404-style errors in dev.

## Root cause

Inside the container the dev server was listening on `::1` only
(`/proc/net/tcp6` → `...01000000:0BDC` = localhost:3036). Docker's port proxy
forwards host connections into the container, where they are refused.

The compose file set `VITE_DEV_SERVER_HOST: 0.0.0.0` — but that variable is only
what the **Rails side dials** for SSR/proxy fetches. The bind address of
`bin/vite dev` comes from **vite_ruby's `VITE_RUBY_HOST`** (default
`localhost`), which was never set.

## Fix

`docker-compose.yaml`, `vite` service environment (fork-owned dev-env file):

```yaml
VITE_RUBY_HOST: 0.0.0.0
```

then `docker compose up -d vite` (recreate, not restart, so the env applies).

## Verification

```sh
curl -s -o /dev/null -w '%{http_code}' http://localhost:3036/vite-dev/@vite/client
# -> 200 from the host; dashboard assets load in the browser
```

## Notes / related

- Easy to misdiagnose as the port mapping or a firewall: the mapping was fine,
  the process just wasn't listening on the mapped interface. Check the bind
  (`/proc/net/tcp*` or vite's startup banner — no "Network:" line means
  localhost-only) before touching compose ports.
- Found while verifying
  [2026-07-10-stale-containers-404-after-image-retag.md](./2026-07-10-stale-containers-404-after-image-retag.md).
