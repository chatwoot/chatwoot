# Chatwoot returns 200 but renders a blank screen — Vite ≥6 `allowedHosts` blocks the Rails asset proxy

- **Date**: 2026-07-27
- **Phase**: dev environment / bring-up
- **Area**: docker / frontend

## Symptom

Chatwoot "works" by every server-side measure — `GET /` and the SSO landing page
both return **200** with a full HTML document referencing `v3app.js` — but the
browser shows a **blank screen**. Nothing renders, and the Rails log is clean.

The failure is only visible one level down, in the assets the document asks for:

```console
$ curl -s http://localhost:3000/vite-dev/entrypoints/v3app.js
Blocked request. This host ("vite") is not allowed.
To allow this host, add "vite" to `server.allowedHosts` in vite.config.js.

$ curl -so /dev/null -w '%{http_code}\n' http://localhost:3000/vite-dev/@vite/client
403
```

## Root cause

**Vite ≥ 6 rejects any request whose `Host` header is not allow-listed** (only
`localhost` and bare IPs pass by default) — a DNS-rebinding mitigation.

`vite.config.ts` had no `server` block at all, so the allow-list was the default.
With rails and vite as separate compose services, vite_ruby's `DevServerProxy`
forwards `/vite-dev/*` to `http://vite:3036`, sending `Host: vite` — which Vite
refuses with a 403.

The reason this reads as "working": **Rails serves the HTML document itself**, so
the response code and the page source both look correct. The entire application
is in the Vite bundle, and only that 403s. A `curl` of the page — even one that
greps the body for `v3app` — cannot see the failure. You have to fetch the asset.

Directly hitting the dev server works, which is what makes it confusing:

```console
$ curl -s http://localhost:3036/vite-dev/entrypoints/v3app.js | head -c 60
import { createApp } from "/vite-dev/@fs/app/node_modules/.vite/…   # 200, fine
```

`Host: localhost` is allowed; `Host: vite` is not.

Exposed by the fix in
[the VITE_RUBY_HOST entry](./2026-07-27-rails-missing-vite-ruby-host-oom-autobuild.md):
before it, rails never reached the dev server at all (it autoBuilt and OOM'd, a
hard 500). Pointing it at `vite:3036` turned that 500 into this 403 — a quieter,
more misleading failure.

## Fix

Additive and **inert by default**, per the fork's upstream-diff rule (`vite.config.ts`):

```ts
server: {
  allowedHosts:
    process.env.VITE_ALLOWED_HOSTS?.split(',')
      .map(host => host.trim())
      .filter(Boolean) ?? [],
},
```

Unset, this is `[]` — exactly Vite's own default, so upstream behaviour is
unchanged. The dev compose supplies it on the **vite** service (it is read where
the dev server boots, not where rails runs):

```yaml
  vite:
    environment:
      VITE_ALLOWED_HOSTS: vite,localhost
```

```sh
docker compose -p mesh-crm up -d --force-recreate vite
```

No allow-listing of the public tunnel hostname is needed: the browser only ever
talks to `:3000`, and rails proxies from there.

## Verification

Fetch the asset, not the page:

```sh
curl -so /dev/null -w '%{http_code}\n' http://localhost:3000/vite-dev/entrypoints/v3app.js   # 200
curl -so /dev/null -w '%{http_code}\n' http://localhost:3000/vite-dev/@vite/client            # 200
```

Walked transitively through the tunnel from the SSO landing page — entry scripts
plus the modules `v3app.js` imports (`vue.js`, `vue-i18n.js`, `@sentry_vue.js`,
`dashboard/i18n/index.js`, …) — all 200.

`../agentic-str/scripts/setup/doctor.sh` now checks this directly and reports
*"Chatwoot serves HTML but its SPA bundle is 403 — the page will render BLANK"*.

## Notes / related

- **Lesson worth keeping:** for a single-page app, *"the page returns 200"* is not
  evidence that it works — it only proves the document server is up. Verify at the
  layer of the claim: fetch the bundle the document depends on.
- [2026-07-27 — rails probes Vite on its own localhost, autoBuilds, OOMs](./2026-07-27-rails-missing-vite-ruby-host-oom-autobuild.md) — the preceding failure in this same chain.
- [2026-07-10 — Vite dev server bound to container-localhost](./2026-07-10-vite-dev-server-bound-to-container-localhost.md) — the earlier bind-vs-connect confusion.
