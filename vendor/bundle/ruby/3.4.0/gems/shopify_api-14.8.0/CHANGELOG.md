# Changelog

Note: For changes to the API, see https://shopify.dev/changelog?filter=api
## Unreleased

## 14.8.0

- [#1355](https://github.com/Shopify/shopify-api-ruby/pull/1355) Add support for 2025-01 API version

## 14.7.0

- [#1347](https://github.com/Shopify/shopify-api-ruby/pull/1347) Extend webhook registration to support filters
- [#1344](https://github.com/Shopify/shopify-api-ruby/pull/1344) Allow ShopifyAPI::Webhooks::Registry to update a webhook when fields or metafield_namespaces are changed.
- [#1343](https://github.com/Shopify/shopify-api-ruby/pull/1343) Make ShopifyAPI::Context::scope parameter optional. `scope` defaults to empty list `[]`.
- [#1348](https://github.com/Shopify/shopify-api-ruby/pull/1348) Add config option that will disable the REST API client and REST resources. New apps should use the GraphQL Admin API

## 14.6.0

- [#1337](https://github.com/Shopify/shopify-api-ruby/pull/1337) Fix type for Shop#google_apps_login_enabled
- [#1340](https://github.com/Shopify/shopify-api-ruby/pull/1340) Add support for 2024-10 API version

## 14.5.0

- [#1327](https://github.com/Shopify/shopify-api-ruby/pull/1327) Support `?debug=true` parameter in GraphQL client requests
- [#1308](https://github.com/Shopify/shopify-api-ruby/pull/1308) Support hash_with_indifferent_access when creating REST objects from Shopify responses. Closes #1296
- [#1332](https://github.com/Shopify/shopify-api-ruby/pull/1332) Fixed an issue where `Customer` REST API PUT requests didn't send all of the fields in the `email_marketing_consent` attribute
- [#1335](https://github.com/Shopify/shopify-api-ruby/pull/1335) Add back the `current` methods for `Shop` and `RecurringApplicationCharge` resources

## 14.4.0

- [#1325](https://github.com/Shopify/shopify-api-ruby/pull/1325) Add support for 2024-07 API version
- [#1320](https://github.com/Shopify/shopify-api-ruby/pull/1320) Fix sorbet type on Shop.tax_shipping field

## 14.3.0

- [#1312](https://github.com/Shopify/shopify-api-ruby/pull/1312) Use same leeway for `exp` and `nbf` when parsing JWT
- [#1313](https://github.com/Shopify/shopify-api-ruby/pull/1313) Fix: Webhook Registry now working with response_as_struct enabled
- [#1314](https://github.com/Shopify/shopify-api-ruby/pull/1314)
  - Add new session util method `SessionUtils::session_id_from_shopify_id_token`
  - `SessionUtils::current_session_id` now accepts shopify Id token in the format of `Bearer this_token` or just `this_token`
- [#1315](https://github.com/Shopify/shopify-api-ruby/pull/1315) Add helper/alias methods to `ShopifyAPI::Auth::JwtPayload`:
  - `shopify_domain` alias for `shop` - returns the sanitized shop domain
  - `shopify_user_id` - returns the user Id (`sub`) as an Integer value
  - `expires_at` alias for `exp` - returns the expiration time

## 14.2.0

- [#1309](https://github.com/Shopify/shopify-api-ruby/pull/1309) Add `Session#copy_attributes_from` method

## 14.1.0

- [#1071](https://github.com/Shopify/shopify-api-ruby/issues/1071) Fix FulfillmentEvent class types
- Fix: InventoryItem class `harmonized_system_code` attribute type which can be either integer, string or nil
- Fix: Variant class `inventory_quantity` attribute type which can be either integer, string or nil
- [1293](https://github.com/Shopify/shopify-api-ruby/issues/1293) Add support for using Storefront private access tokens.
- [1302](https://github.com/Shopify/shopify-api-ruby/pull/1302) Deprecated passing the public Storefront access token as a positional parameter to the Storefront GraphQL client in favor of using the named parameter. (You probably want to use the private access token for this client anyway.)
- [1305](https://github.com/Shopify/shopify-api-ruby/pull/1305/) Adds support for the `2024-04` API version.

## 14.0.1

- [#1288](https://github.com/Shopify/shopify-api-ruby/pull/1288) Fix FeatureDeprecatedError being raised without a message.
- [1290](https://github.com/Shopify/shopify-api-ruby/pull/1290) Move deprecation of `ShopifyAPI::Webhooks::Handler#handle` to version 15.0.0

## 14.0.0

- [#1274](https://github.com/Shopify/shopify-api-ruby/pull/1274) ⚠️ [Breaking] Update sorbet and rbi dependencies. Remove support for ruby 2.7. Minimum required Ruby version is 3.0
- [#1282](https://github.com/Shopify/shopify-api-ruby/pull/1282) Fixes a bug where diffing attributes to update not take into account of Array changes and required ids.
- [#1254](https://github.com/Shopify/shopify-api-ruby/pull/1254) Introduce token exchange API for fetching access tokens. This feature is currently unstable and cannot be used yet.
- [#1268](https://github.com/Shopify/shopify-api-ruby/pull/1268) Add [new webhook handler interface](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/webhooks.md#create-a-webhook-handler) to provide `webhook_id ` and `api_version` information to webhook handlers.
- [#1275](https://github.com/Shopify/shopify-api-ruby/pull/1275) Allow adding custom headers in REST Resource HTTP calls.

## 13.4.0

- [#1210](https://github.com/Shopify/shopify-api-ruby/pull/1246) Add context option `response_as_struct` to allow GraphQL API responses to be accessed via dot notation.
- [#1257](https://github.com/Shopify/shopify-api-ruby/pull/1257) Add `api_call_limit` and `retry_request_after` to REST resources to expose rate limit information.
- [#1257](https://github.com/Shopify/shopify-api-ruby/pull/1257) Added support for the 2024-01 API version. This also includes a fix for the `for_hash` option when creating resources.

## 13.3.1

- [#1244](https://github.com/Shopify/shopify-api-ruby/pull/1244) Add `expired?` to `ShopifyAPI::Auth::Session` to check if the session is expired (mainly for user sessions)
- [#1249](https://github.com/Shopify/shopify-api-ruby/pull/1249) Fix bug where mandatory webhooks could not be processed
- [#1250](https://github.com/Shopify/shopify-api-ruby/pull/1250) Remove rails methods .empty? .present? that were breaking CI

## 13.3.0

- [#1241](https://github.com/Shopify/shopify-api-ruby/pull/1241) Add `api_host` to `ShopifyAPI::Context.setup`, allowing the API host to be overridden in `ShopifyAPI::Clients::HttpClient`. This context option is intended for internal Shopify use only.
- [#1237](https://github.com/Shopify/shopify-api-ruby/pull/1237) Skip mandatory webhook topic registration/unregistrations
- [#1239](https://github.com/Shopify/shopify-api-ruby/pull/1239) Update `OAuth.validate_auth_callback` to use `ShopifyApi::Clients::HttpClient`.

## 13.2.0

- [#1183](https://github.com/Shopify/shopify-api-ruby/pull/1189) Added string array support for fields parameter in Webhook::Registry
- [1208](https://github.com/Shopify/shopify-api-ruby/pull/1208) Fix CustomerAddress and FulfillmentRequest methods
- [1225](https://github.com/Shopify/shopify-api-ruby/pull/1225) Support for 2023_10 API version
- [#1186](https://github.com/Shopify/shopify-api-ruby/pull/1186) Extend webhook registration to support metafield_namespaces

## 13.1.0

- [#1183](https://github.com/Shopify/shopify-api-ruby/pull/1183) Added support for API version 2023-07
- [#1157](https://github.com/Shopify/shopify-api-ruby/pull/1157) Fix an issue where read-only attributes are included when saving REST resources
- [#1169](https://github.com/Shopify/shopify-api-ruby/pull/1169) Unpin zeitwerk version from 2.6.5

## 13.0.0

- [#1140](https://github.com/Shopify/shopify-api-ruby/pull/1140) ⚠️ [Breaking] Reformat Http error messages to be JSON parsable.
- [#1142](https://github.com/Shopify/shopify-api-ruby/issues/1142) Restore API version 2022-04, in alignment with [this](https://shopify.dev/changelog/action-required-support-for-api-version-2022-04-extended-to-june-30-2023) changelog notice.
- [#1155](https://github.com/Shopify/shopify-api-ruby/pull/1155) ⚠️ [Breaking] Remove session storage that was deprecated with [#1055](https://github.com/Shopify/shopify-api-ruby/pull/1055). To upgrade, remove `session_storage` from your API context block. ⚠️ [Breaking] GraphQL Proxy now requires `session` to be passed as an argument.
- [#1150](https://github.com/Shopify/shopify-api-ruby/pull/1150) [Patch] Add support for Event topic names.

## 12.5.0

- [#1113](https://github.com/Shopify/shopify-api-ruby/pull/1113) Handle JSON::ParserError when http response is HTML and raise ShopifyAPI::Errors::HttpResponseError
- [#1098](https://github.com/Shopify/shopify-api-ruby/pull/1098) Gracefully handle HTTP 204 repsonse bodies
- [#1104](https://github.com/Shopify/shopify-api-ruby/pull/1104) Allow api version overrides.
- [#1137](https://github.com/Shopify/shopify-api-ruby/pull/1137) Support for 2023_04 API version. Fix reported typing bugs.

## Version 12.4.0

- [#1092](https://github.com/Shopify/shopify-api-ruby/pull/1092) Add support for 2023-01 API version.
- [#1081](https://github.com/Shopify/shopify-api-ruby/pull/1081) Fixed an error when parsing the JSON response body for the AssignedFulfillmentOrder resource.

## Version 12.3.0

- [#1040](https://github.com/Shopify/shopify-api-ruby/pull/1040) `ShopifyAPI::Clients::HttpResponse` as argument for `ShopifyAPI::Errors::HttpResponseError`
- [#1055](https://github.com/Shopify/shopify-api-ruby/pull/1055) Makes session_storage optional. Configuring the API with session_storage is now deprecated. Session persistence is handled by the [shopify_app gem](https://github.com/Shopify/shopify_app) if using Rails.
- [#1063](https://github.com/Shopify/shopify-api-ruby/pull/1063) Fix ActiveSupport inflector dependency
- [#1069](https://github.com/Shopify/shopify-api-ruby/pull/1069) Adds a custom Logger to help write uniform logs across the api and the [shopify_app gem](https://github.com/Shopify/shopify_app)

## Version 12.2.1

- [#1045](https://github.com/Shopify/shopify-api-ruby/pull/1045) Fixes bug with host/host_name requirement.

## Version 12.2.0

- [#1023](https://github.com/Shopify/shopify-api-ruby/pull/1023) Allow custom scopes during the OAuth process

## Version 12.1.0

- [#1017](https://github.com/Shopify/shopify-api-ruby/pull/1017) Add support for `http` with localhost development without using a TLS tunnel

## Version 12.0.0

- [#1027](https://github.com/Shopify/shopify-api-ruby/pull/1027) ⚠️ [Breaking] Remove support for deprecated API version `2021-10` and added support for version `2022-10`
- [#1008](https://github.com/Shopify/shopify-api-ruby/pull/1008) Increase session token JWT validation leeway from 5s to 10s

## Version 11.1.0

- [#1002](https://github.com/Shopify/shopify-api-ruby/pull/1002) Add new method to construct the host app URL for an embedded app, allowing for safer redirect to app inside appropriate shop admin
- [#1004](https://github.com/Shopify/shopify-api-ruby/pull/1004) Support full URL and scheme-less URL when registering HTTP webhooks

## Version 11.0.1

- [#990](https://github.com/Shopify/shopify-api-ruby/pull/991) Validate `hmac` signature of OAuth callback using both old and new API secrets

## Version 11.0.0

- [#987](https://github.com/Shopify/shopify-api-ruby/pull/987) ⚠️ [Breaking] Add REST resources for July 2022 API version, remove support and REST resources for July 2021 (`2021-07`) API version
- [#979](https://github.com/Shopify/shopify-api-ruby/pull/979) Update `ShopifyAPI::Context.setup` to take `old_api_secret_key` to support API credentials rotation
- [#977](https://github.com/Shopify/shopify-api-ruby/pull/977) Fix webhook requests when a header is present having a symbol key (e.g. `:clearance`)

## Version 10.1.0

- [#933](https://github.com/Shopify/shopify-api-ruby/pull/933) Fix syntax of GraphQL query in `Webhooks.get_webhook_id` method by removing extra curly brace
- [#941](https://github.com/Shopify/shopify-api-ruby/pull/941) Fix `to_hash` to return readonly attributes, unless being used for serialize the object for saving - fix issue [#930](https://github.com/Shopify/shopify-api-ruby/issues/930)
- [#959](https://github.com/Shopify/shopify-api-ruby/pull/959) Update `LATEST_SUPPORTED_ADMIN_VERSION` to `2022-04` to align it with the current value

## Version 10.0.3

### Fixed

- [#935](https://github.com/Shopify/shopify-api-ruby/pull/935) Fix issue [#931](https://github.com/Shopify/shopify-api-ruby/pull/931), weight of variant should be float
- [#944](https://github.com/Shopify/shopify-api-ruby/pull/944) Deprecated the `validate_shop` method from the JWT class since we can trust the token payload, since it comes from Shopify.

## Version 10.0.2

- [#929](https://github.com/Shopify/shopify-api-ruby/pull/929) Aligning sorbet dependencies

## Version 10.0.1

### Fixed

- [#919](https://github.com/Shopify/shopify-api-ruby/pull/919) Allow REST resources to configure a deny list of attributes to be excluded when saving
- [#920](https://github.com/Shopify/shopify-api-ruby/pull/920) Set all values received from the API response to REST resource objects, and allow setting / getting attributes with special characters (such as `?`)
- [#927](https://github.com/Shopify/shopify-api-ruby/pull/927) Fix the `ShopifyAPI::AdminVersions` module for backward compatibility

## Version 10.0.0

- Major update to the library to provide _all_ essential functions needed for a Shopify app, supporting embedded apps with session tokens. See the [full list of changes](https://github.com/Shopify/shopify-api-ruby#breaking-change-notice-for-version-1000) here

## Version 9.5.1

- [#891](https://github.com/Shopify/shopify-api-ruby/pull/891) Removed the upper bound on the `activeresource` dependency to allow apps to use the latest version

## Version 9.5

- [#883](https://github.com/Shopify/shopify-api-ruby/pull/883) Add support for Ruby 3.0

## Version 9.4.1

- [#847](https://github.com/Shopify/shopify-api-ruby/pull/847) Update `create_permission_url` method to use grant_options
- [#852](https://github.com/Shopify/shopify-api-ruby/pull/852) Bumping kramdown to fix a security vulnerability

## Version 9.4.0

- [#843](https://github.com/Shopify/shopify-api-ruby/pull/843) Introduce a new `access_scopes` attribute on the Session class.
  - Specifying this in the Session constructor is optional. By default, this attribute returns `nil`.

## Version 9.3.0

- [#797](https://github.com/Shopify/shopify-api-ruby/pull/797) Release new Endpoint `fulfillment_order.open` and `fulfillment_order.reschedule`.

- [#818](https://github.com/Shopify/shopify-api-ruby/pull/818) Avoid depending on ActiveSupport in Sesssion class.

- Freeze all string literals. This should have no impact unless your application is modifying ('monkeypatching') the internals of the library in an unusual way.

- [#802](https://github.com/Shopify/shopify-api-ruby/pull/802) Made `inventory_quantity` a read-only field in Variant

- [#821](https://github.com/Shopify/shopify-api-ruby/pull/821) Add logging based on environment variable, move log subscriber out of `detailed_log_subscriber`.
  The `ActiveResource::DetailedLogSubscriber` no longer automatically attaches when the class is loaded. If you were previously relying on that behaviour, you'll now need to call `ActiveResource::DetailedLogSubscriber.attach_to(:active_resource_detailed)`. (If using the new `SHOPIFY_LOG_PATH` environment setting then this is handled for you).

- Provide `ApiAccess` value object to encapsulate scope operations [#829](https://github.com/Shopify/shopify-api-ruby/pull/829)

## Version 9.2.0

- Removes the `shopify` binary which will be used by the Shopify CLI

## Version 9.1.1

- Make cursor based pagination return relative uri's when fetching next and previous pages. [#726](https://github.com/Shopify/shopify-api-ruby/pull/726)

## Version 9.1.0

- Implements equality operator on `Session` [#714](https://github.com/Shopify/shopify-api-ruby/pull/714)

## Version 9.0.4

- Contains [#708](https://github.com/Shopify/shopify-api-ruby/pull/708) which is a revert for [#655](https://github.com/Shopify/shopify-api-ruby/pull/655) due to the deprecated inventory parameters not being removed correctly in some cases

## Version 9.0.3

- We now raise a `ShopifyAPI::ValidationException` exception when clients try to use `Product` and `Variant` with deprecated inventory-related fields in API version `2019-10` or later. [#655](https://github.com/Shopify/shopify-api-ruby/pull/655) Deprecation and migration information can be found in the following documents:
  - [Product Variant REST API Reference](https://shopify.dev/docs/api/admin-rest/reference/resources/product-variant)
  - [Migrate your app to support multiple locations](https://shopify.dev/tutorials/migrate-your-app-to-support-multiple-locations)
  - [Manage product inventory with the Admin API](https://shopify.dev/tutorials/manage-product-inventory-with-admin-api)
- Added support for the Discount Code API batch endpoints [#701](https://github.com/Shopify/shopify-api-ruby/pull/701)
  - [Create](https://shopify.dev/docs/api/admin-rest/reference/resources/discountcode#batch_create-2020-01)
  - [Show](https://shopify.dev/docs/api/admin-rest/reference/resources/discountcode#batch_show-2020-01)
  - [List](https://shopify.dev/docs/api/admin-rest/reference/resources/discountcode#batch_discount_codes_index-2020-01)
- Fix issue in the README to explicitly say clients need to require the `shopify_api` gem [#700](https://github.com/Shopify/shopify-api-ruby/pull/700)

## Version 9.0.2

- Added optional flag passed to `initialize_clients` to prevent from raising the `InvalidSchema` exception [#693](https://github.com/Shopify/shopify-api-ruby/pull/693)

## Version 9.0.1

- Added warning message if API version used is unsupported or soon to be unsupported [#685](https://github.com/Shopify/shopify-api-ruby/pull/685)
- Take into account "errors" messages from response body [#677](https://github.com/Shopify/shopify-api-ruby/pull/677)

## Version 9.0.0

- Breaking change: Improved GraphQL client [#672](https://github.com/Shopify/shopify-api-ruby/pull/672). See the [client docs](docs/graphql.md) for usage and a migration guide.

- Added options hash to create_permission_url and makes redirect_uri required [#670](https://github.com/Shopify/shopify-api-ruby/pull/670)

- Release new Endpoint `fulfillment_order.locations_for_move` in 2020-01 REST API version [#669](https://github.com/Shopify/shopify-api-ruby/pull/669)

- Release new Endpoints for `fulfillment` in 2020-01 REST API version [#639](https://github.com/Shopify/shopify-api-ruby/pull/639):

  - `fulfillment.create` with `line_items_by_fulfillment_order`
  - `fulfillment.update_tracking`
  - `fulfillment.cancel`

- Release new Endpoints for `fulfillment_order` in 2020-01 REST API version [#637](https://github.com/Shopify/shopify-api-ruby/pull/637):

  - `fulfillment_order.fulfillment_request`
  - `fulfillment_order.fulfillment_request.accept`
  - `fulfillment_order.fulfillment_request.reject`
  - `fulfillment_order.cancellation_request`
  - `fulfillment_order.cancellation_request.accept`
  - `fulfillment_order.cancellation_request.reject`

- Release new Endpoints `fulfillment_order.move`, `fulfillment_order.cancel` and `fulfillment_order.close` in 2020-01 REST API version [#635](https://github.com/Shopify/shopify-api-ruby/pull/635)

- Release new Endpoint `order.fulfillment_orders`, and active resources `AssignedFulfillmentOrder` and `FulfillmentOrder` in 2020-01 REST API version [#633](https://github.com/Shopify/shopify-api-ruby/pull/633)

## Version 8.1.0

- Release 2020-01 REST ADMIN API VERSION [#656](https://github.com/Shopify/shopify-api-ruby/pull/656)
- Release new Endpoint `collection.products` and `collection.find()` in 2020-01 REST API version [#657](https://github.com/Shopify/shopify-api-ruby/pull/657)
- Enrich 4xx errors with error message from response body [#647](https://github.com/Shopify/shopify-api-ruby/pull/647)
- Make relative cursor based pagination work across page loads [#625](https://github.com/Shopify/shopify-api-ruby/pull/625)
- Small ruby compat fix [#623](https://github.com/Shopify/shopify-api-ruby/pull/623)
- Small consistency change [#621](https://github.com/Shopify/shopify-api-ruby/pull/621)

## Version 8.0.0

- Api Version changes [#600](https://github.com/Shopify/shopify-api-ruby/pull/600)
  - Remove static Api Version definitions.
  - Introduces Api Version lookup modes: `:define_on_unknown` and `:raise_on_unknown`
  - See [migration notes](README.md#-breaking-change-notice-for-version-800-)
- `Session.valid?` checks that api_version `is_a?(ApiVersion)` instead of `present?`
- `ApiVersion::NullVersion` cannot be instantiated and now has a `match?` method [#615](https://github.com/Shopify/shopify-api-ruby/pull/615/files)
- Introduces new Collection endpoint for looking up products without knowing collection type. Only available if ApiVersion is `:unstable` [#609](https://github.com/Shopify/shopify-api-ruby/pull/609)

## Version 7.1.0

- Add 2019-10 to known API versions
- Add support for cursor pagination [#594](https://github.com/Shopify/shopify-api-ruby/pull/594) and
  [#611](https://github.com/Shopify/shopify-api-ruby/pull/611)
- `ShopifyAPI::Base.api_version` now defaults to `ShopifyAPI::ApiVersion::NullVersion` instead of `nil`. Making requests without first setting an ApiVersion raises `ApiVersionNotSetError` instead of `NoMethodError: undefined method 'construct_api_path' for nil:NilClass'` [#605](https://github.com/Shopify/shopify-api-ruby/pull/605)

## Version 7.0.2

- Add 2019-07 to known API versions.

## Version 7.0.1

- Support passing version string to `ShopifyAPI::Base.api_version` [#563](https://github.com/Shopify/shopify-api-ruby/pull/563)

## Version 7.0.0

- Removed support for `ActiveResouce` < `4.1`.
- Removed `ShopifyAPI::Oauth`.
- Added api version support, See [migration
  notes](README.md#-breaking-change-notice-for-version-700-)
- Changed `ShopifyAPI::Session` method signatures from positional to keyword
  arguments, See [migration notes](README.md#-breaking-change-notice-for-version-700-)
- Add support for newer call limit header `X-Shopify-Shop-Api-Call-Limit`.
- Removed all Ping resources.

## Version 6.0.0

- Removed undocumented `protocol` and `port` options from `ShopifyAPI::Session`.

## Version 5.2.4

- Added `currency` parameter to `ShopifyAPI::Order#capture`. This parameter is required for apps that belong to the
  multi-currency beta program.

## Version 5.2.3

- Update delivery confirmation resource to delivery confirmation details resource.

## Version 5.2.2

- Add delivery confirmation endpoint to Ping resources.

## Version 5.2.1

- Log warning when Shopify indicates deprecated API call was performed

## Version 5.2.0

- Added `ShopifyAPI::Currency` to fetch list of supported currencies on a shop
- Added `ShopifyAPI::TenderTransaction` to fetch list of transactions on a shop
- Fixed bug with X-Shopify-Checkout-Version on ShopifyAPI::Checkout header being applied to all requests

## Version 5.1.0

- Added `ShopifyAPI::Publications`
- Added `ShopifyAPI::ProductPublications`
- Added `ShopifyAPI::CollectionPublications`
- Added support for new collection products endpoint from `ShopifyAPI::Collection#products`

## Version 5.0.0

- Breaking change: `ShopifyAPI::Checkout` now maps to the Checkout API, rather than the Abandoned Checkouts API
  - See the README for more details
- Added `ShopifyAPI::AbandonedCheckout`
- Added support for X-Shopify-Checkout-Version header on `ShopifyAPI::Checkout`
- Added `ShopifyAPI::ShippingRate`
- Added `ShopifyAPI::Payment`
- Added support for `Checkout::complete` endpoint
- Fixed session handling support for Rails 5.2.1

## Version 4.13.0

- Added `ShopifyAPI::ApiPermission` resource for uninstalling an application
- Added a deprecation warning to `ShopifyAPI::OAuth`

## Version 4.12.0

- Added support for the GraphQL API

## Version 4.11.0

- Added `ShopifyAPI::InventoryItem`
- Added `ShopifyAPI::InventoryLevel`
- Added `#inventory_levels` method to `ShopifyAPI::Location`

## Version 4.10.0

- Added `ShopifyAPI::AccessScope`

## Version 4.9.1

- Fix a bug with custom properties for orders

## Version 4.9.0

- Added `ShopifyAPI::PriceRule`
- Added `ShopifyAPI::DiscountCode`

## Version 4.8.0

- Added `add_engagements` to `ShopifyAPI::MarketingEvent`

## Version 4.7.1

- Added support for URL parameter (e.g. limit & page) to ShopifyAPI::Metafields
- Added support for URL parameter (e.g. limit & page) to metafield operator in ShopifyAPI::Shop

## Version 4.7.0

- Removed the mandatory `application_id` parameter from `ShopifyAPI::ProductListing` and `ShopifyAPI::CollectionListing`
- Fixed a bug related to the non-standard primary key for `ShopifyAPI::ProductListing` and `ShopifyAPI::CollectionListing`

## Version 4.6.0

- Added `ShopifyAPI::Report`

## Version 4.5.0

- Added `ShopifyAPI::MarketingEvent`

## Version 4.4.0

- Added `ShopifyAPI::CustomerInvite`
- Support for Customer#send_invite endpoint

## Version 4.3.8

- Added `ShopifyAPI::ResourceFeedback`

## Version 4.3.7

- Added support for `complete` in `ShopifyAPI::DraftOrder`

## Version 4.3.6

- Fixed the `customer_saved_search_id` param in `ShopifyAPI::CustomerSavedSearch#customers`.

## Version 4.3.5

- Added support for online mode access tokens, token expiry, and associated_user information.
- Added `ShopifyAPI::DraftOrder`
- Added `ShopifyAPI::DraftOrderInvoice`

## Version 4.3.4

- Added `ShopifyAPI::ProductListing`
- Added `ShopifyAPI::CollectionListing`

## Version 4.3.3

- Added `ShopifyAPI::StorefrontAccessToken`

## Version 4.3.2

- Relax Ruby version requirement to >= `2.0`

## Version 4.3.1

- Support for ShopifyAPI::ApplicationCredit

## Version 4.3.0

- Require Ruby >= `2.3.0`
- Use inheritance instead of the deprecated Rails `Module#alias_method_chain`

## Version 4.2.2

- Support for AccessToken#delegate endpoint

## Version 4.2.1

- Support for Users and Discounts (Shopify Plus only)
- Adds Customer#account_activation_url method
- Adds ability to open a fulfillment.

## Version 4.2.0

- Threadsafety is now compatible with the latest ActiveResource master

## Version 4.1.1

- Added explicit 90 second timeout to `ShopifyAPI::Base`

## Version 4.0.7

- Added `ShippingAPI::ShippingZone`

## Version 4.0.6

- Replaced `cancelled` with `expired` in `ShopifyAPI::ApplicationCharge`

## Version 4.0.5

- Added `pending`, `cancelled`, `accepted`, `declined` helper methods to `ShopifyAPI::ApplicationCharge`

## Version 4.0.4

- Fixed truthiness for order cancellations. Requests are now sent in the request body and as JSON

## Version 4.0.3

- Fixed hmac signature validation for params with delimiters (`&`, `=` or `%`)

## Version 4.0.2

- Verify that the shop domain is a subdomain of .myshopify.com which creating the session

## Version 4.0.1

- Added `ShopifyAPI::OAuth.revoke` for easy token revocation.

## Version 3.2.6

- Fixed CustomerSavedSearch#customers method to now correctly return only relevant customers

## Version 3.2.5

- More useful error messages for activating nil sessions
- Add tests for commonly deleted objects, and metafield tests, fix naming error in order_risk_test.rb

## Version 3.2.4

- No API changes

## Version 3.2.3

- Added pry to the CLI

## Version 3.2.2

- Temporary fix for the CLI
- Add a specific exception for signature validation failures

## Version 3.2.1

- Added CarrierService resource
- Added optionally using threadsafe ActiveResource (see readme)
- Fixed bug in validate_signature

## Version 3.2.0

- in Session::request_token params is no longer optional, you must pass all the params and the method will now extract the code
- Fixed JSON errors handling (#103)
- Fixed compatibility with Ruby 2.1.x (#83)
- Fixed getting parent ID from nested resources like Variants (#44)
- Cleaned up compatibility with ActiveResource 4.0.x
- Added OrderRisk resource
- Added FulfillmentService resource
- Removed discontinued ProductSearchEngine resource
- Added convenience method Customer#search (#45)

## Version 3.1.8

- Expose `index` and `show` actions of `Location`
- Added create_permission_url and request_token helper methods
- Edited the readme to better describe the getting started procedure

## Version 3.1.7

- Expose `authors` and `tags` action on Article

## Version 3.1.6

- Add LineItem::Property resource

## Version 3.1.5

- Expose `orders` action on Customer

## Version 3.1.3

- Expose `complete` action on Fulfillment

## Version 3.1.2

- Includes port in domain URI (when other than http/80 or https/443)
- Adds access to CustomerSavedSearch
- Adds resources: Order::DefaultAddress, Client::ClientDetails, Announcement
- Allows access to Articles without a blog_id
- Moves encode and as_json overrides to ShopifyAPI::Base scope
- Exposes the `order` action in SmartCollection for general use

## Version 3.0.3

- Add a `customers` helper method to the CustomerGroup resource

## Version 3.0.2

- Brevity in require statements

## Version 3.0.1

- Fix saving nested resources in ActiveResource 3.1+

## Version 3.0.0

- Added support for OAuth Authentication
- Removal of support for Legacy Authentication
- Added Cart resource

## Version 2.3.0

- Fix double root bug with ActiveSupport 3.2.0
- Add metafields methods on Customer resource
- Fix prefix_options on assets returned from Asset.find

## Version 2.2.0

- Fix issues with resources that have both direct and namespaced routes
- Added detailed logger to help with debugging ActiveResource
  requests/responses
- Add fulfillment#cancel

## Version 2.1.0

- Fix JSON errors handling
- Remove global limit from ShopifyAPI::Limits

## Version 2.0.0

- Bump to 2.0.0 as this release breaks Rails 2 compatibility; we're now officially only supporting Rails 3. Rails 2 devs can follow the rails2 tag in this repo to know where we broke off
- Refactored resources into their own source files
- Added API limits functionality
- Patched ActiveResource issue with roots in JSON
- Added pending, cancelled, accepted, and declined convenience methods to ShopifyAPI::RecurringApplicationCharge
- ShopifyAPI::Session#temp now available as a convenience method to support temporarily switching to other shops when making calls
- Fixes to `shopify console` CLI tool

## Version 1.2.5

- Fix for Article#comments

## Version 1.2.4

- Added Article#comments
- Added Order#cancel
- Added Comment#restore, #not_spam

## Version 1.2.3

- Added Customer, CustomerGroup support

## Version 1.2.2

- Added ScriptTag support

## Version 1.2.1

- Allow abbreviated names for all commands like rails does, e.g. 'shopify c' instead of 'shopify console'
- Fix Variant to support accessing both nested variants with a product prefix as well as top level variants directly
- Add 'grande' to supported product image size variants

## Version 1.2.0

- Command-line interface
- Allow custom params when fetching a single Asset

## Version 1.1.3 (November 4, 2010)

- Add ProductSearchEngines resource

## Version 1.1.2 (October 20, 2010)

- Fix for users of ActiveResource 3.x

## Version 1.1.1 (October 5, 2010)

- Remove hard coded xml formatting in API calls
- Remove jeweler stuff
- Ruby 1.9 encoding fix

## Version 1.1.0 (September 24, 2010)

- Add new Events API for Shop, Order, Product, CustomCollection, SmartCollection, Page, Blog and Article
- Add new 'compact' product image size variant
- Rails 3 fix: attribute_accessors has to be explicitly included since activesupport 3.0.0

## Version 1.0.6

- Add metafields
- Add latest changes from Shopify including asset support, token validation and a common base class

## Version 1.0.0

- extracting ShopifyAPI from Shopify into Gem
