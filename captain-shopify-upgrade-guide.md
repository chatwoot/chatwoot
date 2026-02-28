# Captain + Shopify Upgrade — Investigation and Implementation

## 1. Objective

Document the investigation, fixes, and validation steps for Shopify-powered Captain flows in Chatwoot, focused on:

- Product search reliability
- Order lookup reliability
- Runtime observability (logs)

This guide reflects the final state where **order lookup is by contact email/phone only** (not by order ID).

## 2. Reported Symptoms

### Product flow

- Captain returned incomplete/incorrect product answers for known products.
- Shopify REST API warning was observed for `products.json` deprecation.

### Order flow

- Customer had a valid Shopify order visible in UI.
- Captain still responded with:
  - `I need the contact email or phone number...`
- Logs showed:
  - `shopify_get_orders_identity_resolved ... email_present: false, phone_present: false`
  - `missing_identifier`

## 3. Root Cause

For order lookup, Captain tool identity was initially resolved from `state[:contact]` only.

- In the failing conversation, contact state had:
  - `contact.email = nil`
  - `contact.phone_number = nil`
- User shared email in message text, but tool did not use message text/history for identity.

## 4. Final Implementation Summary

## 4.1 Product search improvements

- Added stronger logging around Shopify client initialization and product search.
- Added fallback matching strategy in product search when strict title filtering produced empty results.

## 4.2 Order lookup improvements (final behavior)

- Kept Shopify order lookup API in service as:
  - `orders_for_contact(email:, phone_number:, limit:)`
- Added robust identity resolution for Captain order tool:
  - Explicit tool args (if provided by model)
  - Contact state
  - Current user input text (`captain_v2_trace_current_input`)
  - User trace history (`captain_v2_trace_input`) for confirmation turns like `Yes`
- Final outcome: order lookup remains **email/phone based**, but now survives missing contact fields when identity exists in conversation text.

## 4.3 Error handling and UX

- Missing identifier message is:
  - `I need the contact email or phone number to look up Shopify orders.`
- Domain/provider errors are mapped to safe user-facing messages.

## 4.4 Prompt guidance

- Captain prompt guidance for Shopify order queries remains generic for order lookup via Shopify order tool.

## 5. Key Files

- Service:
  - `app/services/integrations/shopify/client_service.rb`
  - `app/services/integrations/shopify/products_service.rb`
  - `app/services/integrations/shopify/orders_service.rb`
- Captain tools:
  - `enterprise/lib/captain/tools/shopify_base_tool.rb`
  - `enterprise/lib/captain/tools/shopify_search_products_tool.rb`
  - `enterprise/lib/captain/tools/shopify_get_orders_tool.rb`
- Prompt:
  - `enterprise/lib/captain/prompts/assistant.liquid`
- Specs:
  - `spec/services/integrations/shopify/products_service_spec.rb`
  - `spec/services/integrations/shopify/orders_service_spec.rb`
  - `spec/enterprise/lib/captain/tools/shopify_search_products_tool_spec.rb`
  - `spec/enterprise/lib/captain/tools/shopify_base_tool_spec.rb`
  - `spec/enterprise/lib/captain/tools/shopify_get_orders_tool_spec.rb`

## 6. QA Checklist

### Product search

1. Ask for a known product keyword (example: `Do you have snowboard?`).
2. Verify Captain returns matching Shopify products with links.
3. Check logs for:
   - `shopify_search_products_requested`
   - `ProductsService ... search_products`
   - fallback log path when strict title match is empty

### Order lookup (email/phone)

1. Ensure contact sidebar may have empty email/phone.
2. Ask: `Where is my order russel.winfield@example.com?`
3. Verify Captain resolves identity and attempts Shopify lookup.
4. Confirmation flow:
   - User provides email in earlier turn
   - Later replies only `Yes`
   - Verify tool still resolves email from trace history and proceeds
5. Check logs for:
   - `shopify_get_orders_requested`
   - `shopify_get_orders_identity_resolved` with `email_present: true` or `phone_present: true`
   - no `missing_identifier` when identity exists in message/history

## 7. Spec/Lint Commands Used

```bash
bundle exec rspec spec/services/integrations/shopify/orders_service_spec.rb \
  spec/enterprise/lib/captain/tools/shopify_base_tool_spec.rb \
  spec/enterprise/lib/captain/tools/shopify_get_orders_tool_spec.rb
```

```bash
bundle exec rubocop \
  app/services/integrations/shopify/orders_service.rb \
  enterprise/lib/captain/tools/shopify_base_tool.rb \
  enterprise/lib/captain/tools/shopify_get_orders_tool.rb \
  spec/services/integrations/shopify/orders_service_spec.rb \
  spec/enterprise/lib/captain/tools/shopify_get_orders_tool_spec.rb
```

## 8. Known Non-Blocking Noise

- Sidekiq scheduled `Discord::PollAllChannelsJob` may fail with:
  - `NameError: uninitialized constant Discord`
- This is unrelated to Shopify Captain product/order behavior.

## 9. Rollback Guidance

If required, rollback can be done by reverting Shopify-related tool/service commits only:

- Revert the Shopify service/tool/spec files listed in Section 5.
- Re-run the spec and rubocop commands in Section 7.

## 10. Missed in This Iteration (Planned for Next Version)

The following items were identified during implementation/testing but intentionally deferred:

1. Shopify order lookup by order ID (optional mode)
- We validated this path technically, but final behavior in this release is email/phone-only.
- Next version plan:
  - Add `order_id` lookup behind a feature flag.
  - Keep email/phone as default to avoid accidental misrouting.

2. Contact identity persistence from conversation
- Current fix resolves identity from message/trace at runtime.
- Next version plan:
  - Optionally persist verified email/phone back to contact profile (with guardrails), so subsequent turns need fewer recoveries.

3. Shopify API modernization (REST -> GraphQL)
- Logs still show REST deprecation warnings for product endpoints.
- Next version plan:
  - Move product/order reads to Shopify GraphQL Admin API.
  - Preserve response contracts expected by Captain tools.

4. End-to-end regression suite for conversational identity flows
- Current tests are service + tool unit specs.
- Next version plan:
  - Add integration-level specs for real multi-turn conversation flows:
    - email in first turn + `Yes` confirmation turn
    - phone-only lookup
    - empty identity -> prompt for identifier

5. Better operator-facing diagnostics
- Logs are present, but triage still needs manual correlation.
- Next version plan:
  - Add structured log keys and dashboards for:
    - identity source used (`contact`, `current_input`, `trace_history`)
    - tool success/failure reason distribution
    - Shopify error categories by account

6. Non-Shopify scheduled job noise
- `Discord::PollAllChannelsJob` `NameError` is unrelated but pollutes logs.
- Next version plan:
  - Gate/disable scheduler for disconnected integrations in dev/test to reduce noise during Captain investigations.
