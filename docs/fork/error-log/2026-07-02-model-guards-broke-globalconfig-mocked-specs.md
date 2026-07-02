# Model quota guards broke specs that strictly mock GlobalConfig

- **Date**: 2026-07-02
- **Phase**: full-suite verification (pre-commit)
- **Area**: backend / ci

## Symptom

26 upstream spec failures (captain base task service, audio transcription,
LeadSquared conversation mapper, conversation completion) in the full suite —
but only when the fork changes were applied. Representative error:

```text
#<GlobalConfig (class)> received :get with unexpected arguments
  expected: ("BRAND_NAME")
  Failure at: create(:integrations_hook, :leadsquared, ...)
```

Also one legitimate behavioral divergence:
`spec/enterprise/controllers/api/v1/accounts/agents_controller_spec.rb:18`
set up an over-cap state via `create_list` (admin + 4 agents with cap 4) —
the fork's model-level guard now makes over-cap states unreachable, so setup
itself raised `ActiveRecord::RecordInvalid`.

## Root cause

The model-level quota guard resolved limits via `Account#usage_limits`, whose
enterprise chain calls `GlobalConfig.get('ACCOUNT_<X>_LIMIT')` — so **every
factory `create` of a guarded model** made GlobalConfig calls that upstream
never made at the model layer. Any upstream spec that mocks GlobalConfig
strictly (`allow(GlobalConfig).to receive(:get).with('BRAND_NAME')`) then
failed on the unexpected argument.

## Fix

1. `Custom::EntitlementService#limit_for` resolves limits from the account's
   own `limits` jsonb (→ `ChatwootApp.max_limit`), never touching
   GlobalConfig/Redis — cheaper per save, and invisible to upstream mocks.
   `Custom::Account::PlanUsageAndLimits#usage_limits` uses the same lean
   resolution for fork keys. Trade-off recorded in ENTITLEMENTS.md: no
   installation-wide `ACCOUNT_<X>_LIMIT` defaults for fork resources.
2. The enterprise agents spec was minimally adjusted (`create_list 4 → 3`) to
   fill the account exactly to cap — its assertion (402 on API create at cap)
   is unchanged and still passes.

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/controllers/slack_uploads_controller_spec.rb \
  spec/enterprise/lib/captain/base_task_service_spec.rb \
  spec/enterprise/lib/captain/conversation_completion_service_spec.rb \
  spec/enterprise/models/account_saml_settings_spec.rb \
  spec/enterprise/services/messages/audio_transcription_service_spec.rb \
  spec/lib/captain/base_task_service_spec.rb \
  spec/services/crm/leadsquared/mappers/conversation_mapper_spec.rb
# => only the 5 pre-existing failures below remain
```

## Notes / related

**Known pre-existing failures (fail identically on clean upstream HEAD in
this environment; not fork-caused):**

- `spec/enterprise/models/account_saml_settings_spec.rb:60` — depended on
  FRONTEND_URL; **fixed** by overriding `FRONTEND_URL: http://localhost:3000`
  in the `test` service of `docker-compose.rspec.yaml` (.env's `0.0.0.0` URL
  was leaking into the test process).
- `spec/controllers/slack_uploads_controller_spec.rb` (4) — **still failing,
  upstream issue**: the controller redirects to an absolute URL built from
  `default_url_options` (`localhost:3000`, hardcoded in
  `config/environments/test.rb:24`) while controller specs run on
  `test.host`, so Rails 7 open-redirect protection raises
  `UnsafeRedirectError`. Fails on clean HEAD; needs an upstream fix
  (`allow_other_host: true` or aligned spec host), not a fork change.
