# SSO-only lockdown leaked from dev .env into specs (and blank values counted as ON)

- **Date**: 2026-07-10
- **Phase**: Phase 5 (auth lockdown) — found during the post-upstream-sync audit
- **Area**: docker / backend

## Symptom

After merging upstream (`cc717c6`), the two "flag off (default) → upstream
behavior intact" specs failed, while every stubbed "flag on" spec passed:

```text
rspec ./spec/custom/controllers/devise_overrides/sessions_controller_spec.rb:13
  expected the response to have a success status code (2xx) but it was 401
rspec ./spec/custom/controllers/devise_overrides/omniauth_callbacks_controller_spec.rb:20
  expected the response to redirect_to(/app/login?email=...&sso_auth_token=...)
```

The 401 body was the fork's own error:
`{"error":"Direct sign-in is disabled...","error_code":"sso_only_login"}` —
i.e. the specs ran with the lockdown **on** even though nothing stubbed it on.

## Root cause

Two stacked problems, neither caused by the upstream merge:

1. **Env leak.** The `test` service in `docker-compose.rspec.yaml` inherits the
   dev `.env` (`env_file: .env`), which sets `ENABLE_SSO_ONLY_LOGIN=true` on
   this machine. `GlobalConfigService.load` falls back to `ENV.fetch`, so the
   "default off" specs actually exercised the flag-on path. The file already
   hard-overrode `POSTGRES_*`/`REDIS_URL`/`FRONTEND_URL` for exactly this
   reason but not this flag. (Once read, the value is also cached in the test
   Redis by `GlobalConfig`, so it kept failing across runs until the
   `redis-test` container was recreated.)
2. **Blank counted as ON.** `Custom::Concerns::SsoOnlyLogin#sso_only_login_enabled?`
   used `... != 'false'`. A *blank* value (e.g. an empty
   `ENABLE_SSO_ONLY_LOGIN=` line makes `GlobalConfigService.load` return `nil`)
   therefore enabled the most restrictive auth mode and silently locked out
   every native login.

## Fix

- `docker-compose.rspec.yaml`: hard-override `ENABLE_SSO_ONLY_LOGIN: "false"`
  in the `test` service (specs that need it on stub `GlobalConfigService`).
- `custom/app/controllers/custom/concerns/sso_only_login.rb`: enable only on an
  explicit `'true'` (`.to_s.downcase == 'true'`) instead of `!= 'false'`.

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml down postgres-test redis-test
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rails db:create db:schema:load
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/custom
# -> 103 examples, 0 failures
```

## Notes / related

- Same failure class as
  [2026-07-02-test-env-pointed-at-neon-dev-db.md](./2026-07-02-test-env-pointed-at-neon-dev-db.md):
  the spec stack inheriting dev `.env` values. Rule of thumb: any fork feature
  toggled by a `.env` flag on this machine needs an explicit override in
  `docker-compose.rspec.yaml`.
- The GlobalConfig Redis cache outlives the example (transactions don't cover
  Redis); if a wrong value was ever read, recreate `redis-test` before
  re-running.
