# Every page 500s: rails probes the Vite dev server on its own localhost, falls back to an in-process build, and OOMs

- **Date**: 2026-07-27
- **Phase**: dev environment / bring-up
- **Area**: docker

## Symptom

Every Rails-rendered page (including the SSO landing at `/app/login?…&sso_auth_token=…`)
returns `500` after ~110 s:

```text
ActionView::Template::Error (Vite Ruby can't find entrypoints/v3app.js in the manifests.
  - The last build failed. Try running `bin/vite build --clear --mode=development` manually and check for errors.
Errors:
  FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory
Completed 500 Internal Server Error in 109582ms (ActiveRecord: 2079.2ms | Allocations: 216401)
```

Confusingly, `mesh-crm-vite-1` is **healthy** the whole time and logs a normal start:

```text
VITE v6.4.2  ready in 670 ms
➜  Local:   http://localhost:3036/vite-dev/
```

## Root cause

`vite_ruby` decides "dev server vs. built manifest" by probing **`VITE_RUBY_HOST`**
— not `VITE_DEV_SERVER_HOST`, which is only the address Vite itself binds to. The
compose set `VITE_DEV_SERVER_HOST: vite` on the `rails` service but left
`VITE_RUBY_HOST` unset, so vite_ruby fell back to its `localhost` default and probed
`localhost:3036` **inside the rails container**, where nothing listens:

```sh
docker compose -p mesh-crm exec -T rails sh -c \
  'curl -so /dev/null -w "%{http_code}\n" http://vite:3036/vite-dev/; \
   curl -so /dev/null -w "%{http_code}\n" http://localhost:3036/vite-dev/'
# vite:3036      -> 403   (reachable)
# localhost:3036 -> 000   (nothing there)  ← what vite_ruby was actually asking
```

Concluding the dev server was down, `autoBuild: true` (`config/vite.json`,
development) made **rails** shell out to `vite build` in its own container, which
exhausts the Node heap and leaves no manifest — hence the "can't find entrypoints"
error on every subsequent render. The OOM is the symptom; the wrong probe host is
the cause.

## Fix

Set the probe host on the `rails` service in `docker-compose.yaml`:

```yaml
    environment:
      VITE_DEV_SERVER_HOST: vite
      VITE_RUBY_HOST: vite      # ← what vite_ruby actually reads
```

`docker compose restart` is not enough — compose only re-reads service
`environment`/`env_file` when the container is created:

```sh
docker compose -p mesh-crm up -d --force-recreate rails
```

No app code changed. Assets still reach the browser over `:3000` only, because
vite_ruby's `DevServerProxy` middleware forwards `/vite-dev/*` from rails to
`vite:3036` — which is what keeps this working behind the Cloudflare tunnel, where
`:3036` is not published.

## Verification

```sh
docker compose -p mesh-crm exec -T rails sh -c 'echo $VITE_RUBY_HOST'   # -> vite
curl -s -o /dev/null -w '%{http_code}\n' http://localhost:3000/          # -> 200 (fast, no 110 s build)
```

End-to-end through the tunnel, the meta-saas SSO bounce now returns the document:

```sh
curl -s -o /dev/null -w '%{http_code}\n' \
  "https://mesh-crm.<domain>/app/login?email=agent-<uid>@handoff.local&sso_auth_token=<tok>"
# -> 200, body references v3app + vite-dev, no "can't find entrypoints"
```

> ⚠ **That check was not sufficient, and this fix alone did not make Chatwoot
> usable.** A 200 on the HTML document only proves Rails is serving; the entire
> SPA is in the Vite bundle it references. Pointing rails at `vite:3036` turned
> the 500 into a **403 on every asset**, which renders a blank screen behind a
> 200 — see
> [Vite `allowedHosts` blocks the Rails asset proxy](./2026-07-27-vite-allowed-hosts-blocks-rails-proxy-blank-spa.md).
> Verify by fetching `/vite-dev/entrypoints/v3app.js`, not the page.

## Notes / related

- Mirror image of
  [2026-07-10 — Vite dev server bound to container-localhost](./2026-07-10-vite-dev-server-bound-to-container-localhost.md):
  that one was Vite **binding** to the wrong interface, this one is rails
  **probing** the wrong one. Both come from the two env vars being easy to
  confuse — `VITE_DEV_SERVER_HOST` = bind, `VITE_RUBY_HOST` = probe/connect.
- Surfaced while fixing the meta-saas "Open workspace" SSO bounce; see
  `agentic-str/docs/troubleshooting/116-*.md` and `117-*.md` for the other two
  defects in that same chain.
