# White-Label / Branding Pass

Runs **last** (after enforcement + AI loop are stable). Config-first: exhaust
installation configs and i18n before touching code, and never rename routes,
headers, or payload keys for branding.

## Layer 1 — Installation configs (no code)

Defined in `config/installation_config.yml` (anchors around lines 17-53),
editable at runtime via Super Admin → App Config, or seedable per environment:

| Config | Use |
| --- | --- |
| `INSTALLATION_NAME` | Product name across UI (consumed by `useBranding`) |
| `BRAND_NAME` | Brand string in emails/footers |
| `LOGO`, `LOGO_DARK`, `LOGO_THUMBNAIL` | App logos (URLs) |
| `BRAND_URL`, `WIDGET_BRAND_URL` | "Powered by" targets and widget branding |
| `TERMS_URL`, `PRIVACY_URL` | Legal links |

Set via console for scripted setup:
`docker compose run --rm rails bundle exec rails runner "InstallationConfig.where(name: 'INSTALLATION_NAME').first_or_create!(value: '<Brand>')"`
(follow existing seed patterns in `config/installation_config.yml` /
`db/seeds` rather than ad-hoc SQL).

## Layer 2 — Frontend strings

- Prefer `replaceInstallationName` from `shared/composables/useBranding`
  (already the repo convention, see root CLAUDE.md) over editing copy that
  contains "Chatwoot".
- Only edit `en.json` (frontend) / `en.yml` (backend); other locales are
  community-managed.
- Onboarding and empty-state copy: audit with
  `rg -n "Chatwoot" app/javascript --type-add 'vue:*.vue' -t vue -t js | rg -v useBranding`
  and route each hit through the composable or i18n.

## Layer 3 — Static assets

Replace files in place (same names/paths — renames break references):

- `public/favicon*`, `public/apple-touch-icon*`, badge/monogram PNGs
- PWA manifest icons (`public/` + verify `DISPLAY_MANIFEST` config)
- Widget/SDK bubble assets if the widget is branded

Regenerate favicon variants from one source image with a generator
(e.g. `docker compose run --rm vite pnpm dlx pwa-asset-generator <logo.svg> public/`)
instead of hand-editing sizes; verify output names match the originals.

## Layer 4 — Emails

- Mailer layouts/templates: confirm they read `BRAND_NAME`/`GlobalConfig`
  (audit `app/views/mailers/`, `app/mailers/`); replace hardcoded "Chatwoot"
  with config reads in `custom/` view overrides
  (`config.paths['app/views'].unshift('custom/app/views')` — see
  ARCHITECTURE.md bootstrap).
- Sender name/address come from `MAILER_SENDER_EMAIL` / mailer configs in
  `.env` — environment, not code.

## Cautions

- `X-Chatwoot-*` webhook headers are a public contract — **do not rebrand**.
- Gem/module namespaces, route helpers, DB names: out of scope.
- After asset swaps run a full build
  (`docker compose run --rm vite pnpm build` or the dev server) and click
  through login, onboarding, widget, and one email preview to catch broken
  references.

## Acceptance

- No visible "Chatwoot" in: app shell, onboarding, empty states, widget,
  transactional emails, browser tab (title + favicon) — except legally
  required license/attribution surfaces you explicitly choose to keep.
- All routes and API responses byte-compatible with pre-branding behavior
  (regression suite green).
