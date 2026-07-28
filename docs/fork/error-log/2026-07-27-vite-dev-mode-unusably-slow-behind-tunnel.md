# "Chatwoot never opens": Vite dev mode serves ~1600 unbundled modules through the tunnel (~2 min blank page)

- **Date**: 2026-07-27
- **Phase**: dev environment / bring-up
- **Area**: docker / frontend

## Symptom

Clicking **Open workspace** in mesh-dash redirects correctly, the SSO token is
accepted, the URL becomes `/app/accounts/<id>/dashboard` — and the browser shows
a **blank white page**. Long enough that it reads as broken, not slow.

Every server-side check passes, which is what makes it so misleading:

```console
$ curl -so /dev/null -w '%{http_code}\n' <sso-url>                       # 200
$ curl -so /dev/null -w '%{http_code}\n' .../vite-dev/entrypoints/v3app.js  # 200
```

The truth is only in the network timings:

```text
GET /vite-dev/dashboard/i18n/locale/es/components.json?import  → 200 ( 5003ms)
GET /vite-dev/dashboard/i18n/locale/is/cannedMgmt.json?import  → 200 (11776ms)
GET /vite-dev/dashboard/i18n/locale/it/companies.json?import   → 304 (25002ms)
GET /vite-dev/dashboard/i18n/locale/no/signup.json?import      → 304 (26500ms)
```

Measured first paint: **~2 minutes**. It does eventually render.

## Root cause

`bin/vite dev` serves the app as **unbundled ES modules** — that is the point of
Vite in dev. Chatwoot has ~40 locales × ~40 i18n namespaces, so the dashboard
pulls on the order of **1600 separate module requests**, each one traversing:

```
browser → Cloudflare tunnel → Rails (vite_ruby DevServerProxy) → Vite :3036
```

On one machine over loopback that is unnoticeable. Through a tunnel plus a Rack
proxy hop, per-request latency compounds into minutes. Nothing is *failing* —
there is no error to find, which is why every status-code check said "healthy".

## Fix

Run Vite in **build** mode and let Rails serve the precompiled bundle from the
manifest — no dev server in the request path at all. (`Procfile.tunnel` already
chose this; the compose had not.) In `docker-compose.yaml`:

```yaml
  vite:
    environment:
      NODE_OPTIONS: --max-old-space-size=4096   # the full build exceeds the default heap
    command: [bin/vite, build, --watch]         # was: [bin/vite, dev]

  rails:
    environment:
      VITE_RUBY_AUTO_BUILD: "false"             # see trap 1
```

Frontend edits still rebuild automatically. You lose hot-module reload, not the
reload — an acceptable trade for a fork used as infrastructure rather than
developed against.

### Trap 1 — two builders, and the loser deletes the winner's output

With `autoBuild` left at its default `true`, a manifest miss makes **Rails** shell
out to its own `vite build`, inside the rails container, on the default Node heap.
It OOMs after ~100 s (`Ineffective mark-compacts near heap limit`) and 500s the
request. Worse: `vite build` **empties its output directory first**, so the failed
rails build *deletes the good manifest the vite container had just written*. The
symptom flips back to `Vite Ruby can't find entrypoints/v3app.js` with a perfectly
valid build sitting on disk moments earlier.

One builder. `VITE_RUBY_AUTO_BUILD: "false"` on rails.

### Trap 2 — Rails memoizes the manifest at boot

With `autoBuild` off and no dev server, vite_ruby reads the manifest **once** and
caches it. A rails container that started *before* the first build serves 500s
forever, against a manifest that is right there:

```console
$ docker compose -p mesh-crm exec -T rails sh -c 'ls public/vite-dev/.vite/manifest.json'
-rw-r--r-- 1 root root 73147 ... manifest.json     # exists
$ curl -so /dev/null -w '%{http_code}\n' localhost:3000/app/login
500                                                 # still 500
$ docker compose -p mesh-crm restart rails
$ curl -so /dev/null -w '%{http_code}\n' localhost:3000/app/login
200
```

**Order matters: build first, then boot rails.** After any frontend rebuild,
restart rails so it picks up the new hashed filenames.

Note the output dir is `public/vite-dev/`, not `public/vite/` — `config/vite.json`
sets `publicOutputDir: "vite-dev"` for the development environment, and the same
path is used in both modes.

## Verification

Timed, on the same page that took ~2 minutes:

```console
$ for i in 1 2 3; do curl -so /dev/null -w '%{http_code} %{time_total}s\n' localhost:3000/app/login; done
200 2.341173s
200 2.296766s
200 2.362524s
```

Driven in a real headless browser through the tunnel, end to end from the
mesh-dash SSO bounce: the workspace renders (account name, "AI Handoff" inbox,
the signed-in agent user), **zero console errors**, and zero failed requests. The
one script tag is now a single hashed bundle, `/vite-dev/assets/v3app-<hash>.js`.

ActionCable was checked separately and is fine through the tunnel — `/cable`
returns `101 Switching Protocols` both locally and via Cloudflare. The `502`s seen
on `wss://…/cable` in earlier console dumps were collected while rails was
restarting, not a tunnel WebSocket problem.

## Notes / related

- **The lesson this chain keeps teaching:** for a single-page app, a `200` on the
  document proves only that the document server is up. This one went further —
  every individual asset also returned `200`. The failure was the *aggregate*,
  visible only in timings. Verify at the layer of the claim: if the claim is "the
  workspace opens", open it in a browser and look.
- [Vite `allowedHosts` blocks the Rails asset proxy](./2026-07-27-vite-allowed-hosts-blocks-rails-proxy-blank-spa.md) — the preceding failure. In build mode there is no proxy hop, so `VITE_ALLOWED_HOSTS` is inert; it is kept so `bin/vite dev` still works if you switch back.
- [rails probes Vite on its own localhost, autoBuilds, OOMs](./2026-07-27-rails-missing-vite-ruby-host-oom-autobuild.md) — the original OOM, same root shape as trap 1.
