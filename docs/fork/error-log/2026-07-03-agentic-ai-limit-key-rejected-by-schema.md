# agentic_ai limit key rejected by the limits JSON schema

- **Date**: 2026-07-03
- **Phase**: Phase 6 (agentic-AI display surface)
- **Area**: backend

## Symptom

The agentic-AI banner never appeared even after the control plane wrote the
cap. Writing the cap the way the integration contract documents:

```text
PATCH /platform/api/v1/accounts/{id}  { "limits": { "agentic_ai": 500 } }
→ 422 { "limits": [": Invalid data"] }
```

## Root cause

`Custom::Account::PlanUsageAndLimits#validate_limit_keys` builds its JSON schema
from `base_keys + QUOTA_RESOURCES` with `additionalProperties: false`, and
`agentic_ai` is in neither list. So the model rejected every write of the
`agentic_ai` cap. Because the cap could never be stored,
`Custom::Enterprise::Api::V1::AccountsController#agentic_ai_usage_limit` always
saw a blank cap and returned `{}`, so `GET .../limits` never emitted
`agentic_ai` and `AgenticAiLimitBanner.vue` never rendered — the entire feature
described in ENTITLEMENTS.md / CHATWOOT_ENGINE_INTEGRATION.md §5 was unreachable.
It was not caught because no spec exercised writing `agentic_ai` into
`accounts.limits`.

## Fix

- Added `EXTERNAL_LIMIT_KEYS = %w[agentic_ai]` to
  `custom/app/models/custom/account/plan_usage_and_limits.rb` and included it in
  the schema property list. Kept it out of `QUOTA_RESOURCES` on purpose:
  `agentic_ai` is enforced externally (NestJS), so it must be schema-valid but
  must not gain an EntitlementService counter or a 402 create-guard.
- Added specs: schema accepts `agentic_ai`
  (`spec/custom/models/custom/account/plan_usage_and_limits_spec.rb`); the limits
  endpoint surfaces it when a cap is set and omits it otherwise
  (`spec/custom/controllers/enterprise/api/v1/accounts_controller_spec.rb`).

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/custom/models/custom/account/plan_usage_and_limits_spec.rb \
  spec/custom/controllers/enterprise/api/v1/accounts_controller_spec.rb
```

## Notes / related

The doc (§4.1, §5.1) already listed `agentic_ai` as a valid limit key, so this
was a code/doc drift where the code was wrong, not the contract. Related:
`docs/fork/error-log/2026-07-02-limits-endpoint-cloud-shape-pollution.md`.
