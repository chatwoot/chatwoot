# EXTERNAL_LOGIN_URL never reached the login page

- **Date**: 2026-07-03
- **Phase**: Phase 7 (SSO-only auth lockdown)
- **Area**: frontend

## Symptom

With `EXTERNAL_LOGIN_URL` set, a bare/expired visit to `/app/login` still
rendered Chatwoot's login form instead of bouncing to the external app, breaking
the redirect documented in CHATWOOT_ENGINE_INTEGRATION.md §4.5–4.6.

## Root cause

Wrong window object. The SSO-lockdown commit already exposed the value the
right way — `DashboardController#app_config` adds
`EXTERNAL_LOGIN_URL: GlobalConfigService.load('EXTERNAL_LOGIN_URL', '')`, which
flows into `@global_config` and is dumped to **`window.globalConfig`** by the
layout (`vueapp.html.erb`). But `app/javascript/v3/views/login/Index.vue` read
`window.chatwootConfig?.EXTERNAL_LOGIN_URL` — a different, unrelated global that
never carried the key. So the guard `!this.email &&
window.chatwootConfig?.EXTERNAL_LOGIN_URL` was never truthy and the redirect was
dead code.

## Fix

Pointed `Index.vue` at the populated global: `window.globalConfig?.EXTERNAL_LOGIN_URL`
(source: `DashboardController#app_config`). No layout/erb change needed — the
value was already there via the existing `GlobalConfigService` path, so this also
honors both ENV and the Super Admin App Config panel. Empty when unset → the
redirect stays inert by default and dev/tests are unaffected.

## Verification

Manual: set `EXTERNAL_LOGIN_URL` (ENV or Super Admin), load `/app/login` with no
email/sso token → browser redirects to the external URL; unset → Chatwoot's
form renders as before. `pnpm eslint` clean.

## Notes / related

Frontend fork changes are direct OSS edits (Vue/erb has no `prepend_mod_with`
overlay), consistent with the `AgenticAiLimitBanner` mount in `App.vue` and the
`en.json` branding strings. Related:
`custom/app/controllers/custom/devise_overrides/sessions_controller.rb`
(the server-side `ENABLE_SSO_ONLY_LOGIN` half of the same lockdown).
