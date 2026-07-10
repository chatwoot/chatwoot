# Sparse custom_attributes PATCH wiped Chatwoot-owned account state

- **Date**: 2026-07-10
- **Phase**: Phase 6 (agentic-AI display surface) — found in the cross-repo review
- **Area**: backend / webhook (Platform API contract)

## Symptom

No error surfaced — that is the problem. The meta-saas periodic agentic-usage
writeback (`AgenticUsageWritebackService`) PATCHes:

```text
PATCH /platform/api/v1/accounts/{id}
{ "limits": { ...complete caps... }, "custom_attributes": { "agentic_ai_usage": N } }
```

and returned 200. But `Platform::Api::V1::AccountsController#update` does
`assign_attributes`, which REPLACES the whole `custom_attributes` jsonb — so
every writeback run silently erased any other account attribute:
`marked_for_deletion_at` / `marked_for_deletion_reason` (an account scheduled
for deletion becomes unscheduled — or the deletion mailer renders a blank
date), `plan_name`, `billing_currency`, `stripe_customer_id`, onboarding attrs.

## Root cause

Contract mismatch. The integration contract (CHATWOOT_ENGINE_INTEGRATION.md
§4.1, old text) said "writes REPLACE the jsonb — always send the complete
object", but the control plane cannot actually do that safely for
`custom_attributes`: Chatwoot writes its own keys into the same hash
(deletion marks, billing), which the control plane can neither know nor echo
back without a read-modify-write race. The meta-saas adapter was written
against the sparse-patch reading ("an omitted column stays untouched").
Full-object was only ever viable for `limits`, where the control plane owns
every key.

## Fix

Fork-side, so the contract itself becomes safe (any platform caller is
protected, including future ones):

- `custom/app/controllers/custom/platform/api/v1/accounts_controller.rb` —
  `custom_attributes` on **update** now has RFC 7386-style merge-patch
  semantics: sent keys overwrite, omitted keys survive, explicit `null`
  deletes. Create and `limits` keep upstream replace semantics.
- Hook added: `Platform::Api::V1::AccountsController.prepend_mod_with(...)`
  (canonical extension point, no-op upstream).
- Contract docs updated: CHATWOOT_ENGINE_INTEGRATION.md §4.1/§5, ENTITLEMENTS.md.
- meta-saas: adapter comment updated to state the merge-patch semantics
  (no code change needed — its sparse write is now correct as written).

## Verification

```sh
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/custom/controllers/platform/api/v1/accounts_controller_spec.rb
# -> 5 examples, 0 failures (sparse patch preserves marked_for_deletion_at/plan_name;
#    explicit null deletes a key)
docker compose -f docker-compose.yaml -f docker-compose.rspec.yaml run --rm test \
  bundle exec rspec spec/controllers/platform/api/v1/accounts_controller_spec.rb
# -> 21 examples, 0 failures (upstream behavior unchanged for full-object callers)
```

## Notes / related

- Found while auditing the fork against `../meta-saas` (the writeback shipped in
  meta-saas `docs/changes/2026-07-10-agentic-rag-upgrade-and-mcp.md`).
- The paired `limits` write stays full-object on purpose — the control plane
  owns every cap key and resending the complete set is what keeps QuotaGuard
  caps from being wiped (`chatwootLimitsFromEntitlements` in meta-saas).
