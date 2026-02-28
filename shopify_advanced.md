# Shopify Advanced (Implementation-Aligned Runbook)

## Summary
This document reflects the implemented Shopify support for Captain in Chatwoot:
1. Enterprise-only
2. Captain V2-only (`captain_integration_v2`)
3. Phase 1 scope: product search + order lookup
4. Order lookup is by contact identity (`email` / `phone_number`) only

No Captain V1 behavior and no checkout/cart features are included.

## Implemented Tool Surface
1. `shopify_search_products`
2. `shopify_get_orders`

Both tools are registered in:
[`/Users/muhsink/Documents/chatwoot/config/agents/tools.yml`](/Users/muhsink/Documents/chatwoot/config/agents/tools.yml)

## Shopify Scope Requirements
1. Integration helper includes:
- `read_customers`
- `read_orders`
- `read_fulfillments`
- `read_products`
2. `read_products` is required for product search behavior.

Reference:
[`/Users/muhsink/Documents/chatwoot/app/helpers/shopify/integration_helper.rb`](/Users/muhsink/Documents/chatwoot/app/helpers/shopify/integration_helper.rb)

## Core Files
### Services
1. [`/Users/muhsink/Documents/chatwoot/app/services/integrations/shopify/client_service.rb`](/Users/muhsink/Documents/chatwoot/app/services/integrations/shopify/client_service.rb)
2. [`/Users/muhsink/Documents/chatwoot/app/services/integrations/shopify/products_service.rb`](/Users/muhsink/Documents/chatwoot/app/services/integrations/shopify/products_service.rb)
3. [`/Users/muhsink/Documents/chatwoot/app/services/integrations/shopify/orders_service.rb`](/Users/muhsink/Documents/chatwoot/app/services/integrations/shopify/orders_service.rb)

### Captain tools
1. [`/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/tools/shopify_base_tool.rb`](/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/tools/shopify_base_tool.rb)
2. [`/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/tools/shopify_search_products_tool.rb`](/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/tools/shopify_search_products_tool.rb)
3. [`/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/tools/shopify_get_orders_tool.rb`](/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/tools/shopify_get_orders_tool.rb)

### Gating + prompt
1. [`/Users/muhsink/Documents/chatwoot/enterprise/app/models/captain/assistant.rb`](/Users/muhsink/Documents/chatwoot/enterprise/app/models/captain/assistant.rb)
2. [`/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/prompts/assistant.liquid`](/Users/muhsink/Documents/chatwoot/enterprise/lib/captain/prompts/assistant.liquid)

## Service Behavior
### `Integrations::Shopify::ClientService`
1. Loads enabled Shopify hook (`app_id: 'shopify'`).
2. Builds Shopify REST admin client.
3. Parses granted scopes from hook settings.
4. Returns normalized results:
- `:not_connected`
- `:provider_error`
5. Emits structured Rails logs for connection and scope context.

### `Integrations::Shopify::ProductsService`
Method:
- `search_products(query:, limit: 10)`

Behavior:
1. Rejects blank query with `:no_results`.
2. Validates connection and `read_products` scope.
3. Primary search: active products by title.
4. Fallback search: fetch active products with larger limit, then in-memory keyword match against title/vendor/type.
5. Normalizes product payload:
- `id`, `title`, `vendor`, `product_type`, `handle`, `storefront_url`
- first variant `price`
- computed `availability` summary
6. Error mapping:
- `:insufficient_scope`, `:no_results`, `:provider_error`

### `Integrations::Shopify::OrdersService`
Method:
- `orders_for_contact(email:, phone_number:, limit: 10)`

Behavior:
1. Requires at least one identifier (`email` or `phone_number`).
2. Validates connection and scopes `read_customers` + `read_orders`.
3. Runs customer search using `email OR phone`.
4. Fetches orders for first matching customer.
5. Normalizes order payload:
- `id`, `name`, `created_at`, `total_price`, `currency`
- `financial_status`, `fulfillment_status`
- `line_items` (capped)
- `admin_url`
6. Error mapping:
- `:missing_identifier`, `:insufficient_scope`, `:no_results`, `:provider_error`

## Tool Behavior
### Base tool (`Captain::Tools::ShopifyBaseTool`)
1. `active?` requires:
- account feature flag `captain_integration_v2`
- enabled Shopify integration hook
2. Common deterministic domain error formatting.
3. Identity resolution order for order lookup:
- explicit tool args
- `state.contact`
- `state.captain_v2_trace_current_input` (message text parsing)
- `state.captain_v2_trace_input` history (supports confirmation turns like `Yes`)

### `shopify_search_products`
Params:
1. `query` (required)

Behavior:
1. Calls `ProductsService#search_products(query:, limit: 10)`.
2. Returns compact text list with title, price, availability, and product URL.
3. Returns safe fallback messages on domain/provider errors.

### `shopify_get_orders`
Params:
1. `email` (optional)
2. `phone_number` (optional)

Behavior:
1. Resolves identity through base-tool identity resolution.
2. Calls `OrdersService#orders_for_contact(email:, phone_number:, limit: 10)`.
3. Returns compact text list with order metadata, admin URL, and top line items.
4. Returns deterministic fallback messages for missing identity/no results/scope/provider errors.

## Gating Rules
1. Shopify tools are exposed only when Captain V2 is enabled and Shopify is connected.
2. If tool execution is attempted while ineligible, tools return safe non-crashing messages.
3. Existing `available_tool_ids` validation remains source of truth for scenario/tool validity.

## Current Constraints
1. Order lookup is email/phone-based only in this version.
2. No order-ID lookup path is enabled in this implementation.
3. Product and order responses are plain text lists for Captain tool output.

## Verification Coverage
### Service specs
1. Product search success/no-results/scope/provider-error.
2. Product title-empty fallback keyword flow.
3. Orders success by email and by phone.
4. Orders missing identifier/no customer/provider-error.

### Tool specs
1. Active-state gating checks (`V2 off`, `Shopify disconnected`, eligible case).
2. Product tool success/error messaging.
3. Orders tool success/error messaging.
4. Orders identity extraction from:
- state contact
- current input text
- trace history
- explicit tool arguments overriding inferred values

## Notes for Next Version
1. Optional order lookup by explicit order ID (feature-flagged).
2. Optional verified identity persistence to contact profile.
3. REST-to-GraphQL Shopify migration to address deprecation trajectory.
4. More end-to-end conversation-level regression coverage.
