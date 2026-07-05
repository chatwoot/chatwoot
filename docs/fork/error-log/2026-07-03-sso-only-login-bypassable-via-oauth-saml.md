# SSO-only login was bypassable via Google OAuth / SAML

- **Date**: 2026-07-03
- **Phase**: Phase 7 (SSO-only auth lockdown)
- **Area**: backend / security

## Symptom

With `ENABLE_SSO_ONLY_LOGIN=true`, password and MFA-token logins were correctly
rejected (401), but a user could still sign in through **Google OAuth** (and
**SAML**): the callback redirected to `/app/login?email=…&sso_auth_token=…` and
the session was created. The "master lock" was not actually a master lock.

## Root cause

`ENABLE_SSO_ONLY_LOGIN` was enforced only in
`Custom::DeviseOverrides::SessionsController#create`, which guards the
password/MFA path. But OAuth and SAML sign-in run through
`DeviseOverrides::OmniauthCallbacksController#omniauth_success →
sign_in_user`, which **mints a valid `sso_auth_token`** and hands it to the
login page. The session controller's lock allows any `sso_auth_token` request
(`return super if sso_authentication_request?`) because it cannot distinguish an
OAuth-minted token from a legitimate Platform-minted one (§4.5). So OAuth/SAML
sailed straight through the one path the lock lets pass. The documented
mitigation ("also set `ENABLE_GOOGLE_OAUTH_LOGIN=false`") made safety depend on a
second, easily-forgotten config — not a true lock.

## Fix

Blocked OAuth/SAML at the single provider entry point, before any token is
minted, entirely in the overlay (the OSS controller already exposes
`prepend_mod_with` — zero OSS edit):

- New `custom/app/controllers/custom/devise_overrides/omniauth_callbacks_controller.rb`
  overrides `#omniauth_success`: when the lock is on it redirects to
  `/app/login?error=sso-only-login` instead of calling `super`. Both Google
  (base `omniauth_success`) and SAML (enterprise `handle_saml_auth`) funnel
  through this method, so both are covered; the `Custom::` module prepends ahead
  of the enterprise module, so it runs first.
- Extracted the gate into `custom/app/controllers/custom/concerns/sso_only_login.rb`
  (`sso_only_login_enabled?`) and included it in **both** the session and
  omniauth overlays, so the policy cannot drift between the two entry points.
- Platform SSO handoff (§4.5) and impersonation do not pass through omniauth, so
  they are unaffected. Inert when the flag is unset (straight `super`).

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/custom/controllers/devise_overrides
# => 5 examples, 0 failures
```

New spec `spec/custom/controllers/devise_overrides/omniauth_callbacks_controller_spec.rb`:
OAuth callback with the lock **off** still mints an `sso_auth_token`; with the
lock **on** it redirects to `?error=sso-only-login` and no token is issued.

## Notes / related

Doc updated: `CHATWOOT_ENGINE_INTEGRATION.md §4.6` now states the flag blocks
OAuth/SAML server-side and that disabling the OAuth/SAML flags is defense-in-depth,
not required. Related:
`custom/app/controllers/custom/devise_overrides/sessions_controller.rb`
(password/MFA half of the same lock).
