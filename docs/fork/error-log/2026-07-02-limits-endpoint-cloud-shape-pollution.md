# Limits endpoint override polluted the cloud response shape

- **Date**: 2026-07-02
- **Phase**: Phase 6
- **Area**: backend

## Symptom

Upstream enterprise spec failed after adding the fork's limits override:

```text
spec/enterprise/controllers/enterprise/api/v1/accounts_controller_spec.rb:193
expected: {"limits" => {"agents" => {"allowed" => 100000, ...}, ...}}
     got: {"limits" => {"agents" => {"allowed" => nil, ...}, "teams" => ..., ...}}
```

Plus an order-dependent failure: the fork's "stays cloud-gated" spec passed
alone but failed after the enterprise spec file ran in the same process.

## Root cause

1. `Custom::Enterprise::Api::V1::AccountsController#default_limits` merged the
   fork quota keys unconditionally and re-emitted `agents` with
   `allowed: nil` for unlimited — changing the shape of an **existing** key on
   the **cloud** code path, which upstream specs assert with exact equality.
   That broke the additive-only contract rule.
2. Enterprise specs leave `GlobalConfig`/`InstallationConfig` cache state
   (e.g. `DEPLOYMENT_ENV`) behind in Redis, so `ChatwootApp.chatwoot_cloud?`
   leaked `true` into later spec files.

## Fix

- `default_limits` returns `super` untouched when `ChatwootApp.chatwoot_cloud?`;
  fork keys are merged only on self-hosted (where the endpoint previously
  404'd, so nothing existing could depend on the shape).
- `agents` removed from the fork merge entirely — upstream already serves it.
- The fork spec stubs `chatwoot_cloud? => false` explicitly instead of relying
  on ambient config state.

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/enterprise/controllers/enterprise/api/v1/accounts_controller_spec.rb spec/custom
# => 92 examples, 0 failures
```

## Notes / related

General lessons: (a) when overriding a response-building method, gate the
override to the deployment mode the fork owns and never re-emit existing keys;
(b) any fork spec whose behavior depends on `chatwoot_cloud?` /
`GlobalConfig` must stub it explicitly — Redis-backed config cache leaks
across spec files.
