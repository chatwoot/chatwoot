# `shopify_advanced.md` + Implementation Runbook (Enterprise, Captain V2, Products+Orders)

## Summary
Implement advanced Shopify support for Captain as **Enterprise + Captain V2 only**, with **phase 1 limited to product search and order lookup**.  
No Captain V1 work, no cart/checkout work in this phase.

## Deliverables
1. Root doc file: `shopify_advanced.md` (this plan content).
2. Backend Shopify service layer (shared, read-only).
3. Two new Captain built-in tools:
- `shopify_search_products`
- `shopify_get_orders`
4. Tool exposure/runtime gating to Captain V2 + connected Shopify only.
5. Scope update: add `read_products`.
6. Specs for services, tools, and gating.

## Important Interface Changes
1. New Captain tool IDs:
- `shopify_search_products`
- `shopify_get_orders`
2. Shopify required scopes update:
- add `read_products` to `REQUIRED_SCOPES`.
3. No new public REST endpoints for Captain.

## Files to Create

### 1) Shared Shopify services
1. `app/services/integrations/shopify/client_service.rb`
2. `app/services/integrations/shopify/products_service.rb`
3. `app/services/integrations/shopify/orders_service.rb`

### 2) Enterprise Captain tools
1. `enterprise/lib/captain/tools/shopify_base_tool.rb`
2. `enterprise/lib/captain/tools/shopify_search_products_tool.rb`
3. `enterprise/lib/captain/tools/shopify_get_orders_tool.rb`

### 3) Specs
1. `spec/services/integrations/shopify/products_service_spec.rb`
2. `spec/services/integrations/shopify/orders_service_spec.rb`
3. `spec/enterprise/lib/captain/tools/shopify_base_tool_spec.rb`
4. `spec/enterprise/lib/captain/tools/shopify_search_products_tool_spec.rb`
5. `spec/enterprise/lib/captain/tools/shopify_get_orders_tool_spec.rb`

## Files to Modify

1. [`/Users/muhsink/Documents/chatwoot/app/helpers/shopify/integration_helper.rb`](/Users/muhsink/Documents/chatwoot/app/helpers/shopify/integration_helper.rb)
- Add `read_products` to `REQUIRED_SCOPES`.

2. [`/Users/muhsink/Documents/chatwoot/config/agents/tools.yml`](/Users/muhsink/Documents/chatwoot/config/agents/tools.yml)
- Register the 2 new tools with title/description/icon.

3. [`/Users/muhsink/Documents/chatwoot/enterprise/app/models/captain/assistant.rb`](/Users/muhsink/Documents/chatwoot/enterprise/app/models/captain/assistant.rb)
- Add helper `shopify_tools_enabled_for_v2?`.
- Auto-append Shopify tools in `agent_tools` when eligible.
- Filter tool metadata in `available_agent_tools` unless eligible.

4. [`/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/prompts/assistant.liquid`](/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/prompts/assistant.liquid)
- Add short instruction: use Shopify tools for product/order queries before FAQ fallback.

5. Optional refactor only (no contract change):
- [`/Users/muhsink/Documents/chatwoot/app/controllers/api/v1/accounts/integrations/shopify_controller.rb`](/Users/muhsink/Documents/chatwoot/app/controllers/api/v1/accounts/integrations/shopify_controller.rb)
- Reuse `OrdersService` internally for consistency.

## Implementation Details

### A. `ClientService`
Responsibilities:
1. Load connected hook (`app_id: 'shopify'`, status enabled).
2. Build Shopify REST client from hook token.
3. Parse granted scopes from hook settings.
4. Return normalized failure objects for:
- `:not_connected`
- `:provider_error`

### B. `ProductsService`
Method:
- `search_products(query:, limit: 10)`

Behavior:
1. Validate connection + `read_products`.
2. Fetch active products by title query.
3. Normalize output:
- `id`, `title`, `vendor`, `product_type`, `handle`, `storefront_url`
- first variant `price`
- availability summary from variants.
4. Return normalized result/error:
- `:insufficient_scope`, `:no_results`, `:provider_error`.

### C. `OrdersService`
Method:
- `orders_for_contact(email:, phone_number:, limit: 10)`

Behavior:
1. Require at least one identifier (`email` or `phone_number`).
2. Validate connection + scopes `read_customers` and `read_orders`.
3. Search customer by `email OR phone`.
4. Fetch orders for first matched customer.
5. Normalize output:
- `id`, `name`, `created_at`, `total_price`, `currency`
- `financial_status`, `fulfillment_status`
- `line_items` (capped)
- `admin_url`.
6. Return normalized result/error:
- `:missing_identifier`, `:no_results`, `:provider_error`.

### D. `ShopifyBaseTool`
Common behavior:
1. Extend `BasePublicTool`.
2. `active?` true only when:
- `captain_integration_v2` enabled
- Shopify hook enabled for account.
3. Common helpers:
- `v2_enabled?`
- `shopify_connected?`
- `resolve_contact_identity(tool_context.state)`
- scope guard + standardized reconnect message.
4. Tool-safe deterministic messages, no exceptions leaked.

### E. `shopify_search_products` tool
Params:
1. `query` (required string).

Behavior:
1. Call `ProductsService#search_products`.
2. Format compact plain text list (max 10):
- title
- price
- availability
- product URL.
3. Deterministic fallback messages for each domain error.

### F. `shopify_get_orders` tool
Params:
1. none (phase 1).

Behavior:
1. Resolve contact email/phone from conversation state.
2. Call `OrdersService#orders_for_contact`.
3. Format compact plain text list (max 10):
- order name/date/total/status/admin URL
- top line items.
4. Deterministic fallback messages for each domain error.

## Gating Rules (Decision-Complete)
1. Tool visibility in UI:
- Hidden unless `captain_integration_v2` and Shopify connected.
2. Tool execution:
- If invoked when ineligible, return non-execution message (no crash).
3. Scenario validity:
- Existing `available_tool_ids`-based validation remains source of truth.

## Test Cases

### Service specs
1. Product search success with normalized fields.
2. Product no results.
3. Product missing scope.
4. Orders success by email.
5. Orders success by phone.
6. Orders missing identifier.
7. Orders no matching customer.
8. Provider error mapping for both services.

### Tool specs
1. `active?` false when V2 disabled.
2. `active?` false when Shopify disconnected.
3. Product tool success formatting.
4. Product tool missing scope message.
5. Orders tool success formatting.
6. Orders tool missing identity message.
7. Orders tool no-result message.
8. Provider error safe messaging.

### Model/gating specs
1. `available_agent_tools` hides Shopify tools unless eligible.
2. `agent_tools` includes Shopify tools only when eligible.

### Regression
1. Existing Shopify integration request specs still pass.
2. Existing Captain tools unaffected.

## Acceptance Criteria
1. With V2 enabled + Shopify connected + proper scopes:
- “Do you have sneakers?” triggers `shopify_search_products` and returns relevant products with links.
- “Where is my order?” triggers `shopify_get_orders` and returns recent order details.
2. With older Shopify install missing product scope:
- Product tool returns reconnect guidance; no crash.
3. With V2 off or no Shopify connection:
- Shopify tools are not shown and not executed.

## Assumptions
1. Enterprise-only feature is acceptable.
2. Captain V2 only.
3. Phase 1 excludes abandoned checkouts/cart.
4. Plain text output only.
5. English copy updates only where needed.

## `shopify_advanced.md` Content
Use this entire document as the initial content of `shopify_advanced.md` at repo root.
