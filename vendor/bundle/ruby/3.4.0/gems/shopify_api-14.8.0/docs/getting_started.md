# Getting started

This page will outline everything you need to know and the steps you need to follow in order to start using the Shopify Ruby API gem in your app.

## Requirements

- A working knowledge of ruby and a web framework such as Rails or Sinatra
- A custom app already set up in your test store or partner account
- We recommend `ngrok` to tunnel traffic to your localhost for testing

## Installation

Add the following to your Gemfile:

`gem "shopify_api"`

## Steps to use the Gem

### Setup Shopify Context

Start by initializing the `ShopifyAPI::Context` with the parameters of your app by calling `ShopifyAPI::Context.setup` (example below) when your app starts (e.g `application.rb` in a Rails app).

```ruby
ShopifyAPI::Context.setup(
  api_key: "<api-key>",
  api_secret_key: "<api-secret-key>",
  host_name: "<application-host-name>",
  scope: "read_orders,read_products,etc",
  is_embedded: true, # Set to true if you are building an embedded app
  is_private: false, # Set to true if you are building a private app
  api_version: "2021-01" # The version of the API you would like to use
)
```

### Performing OAuth

Next, unless you are making a private app, you need to go through OAuth as described [here](https://shopify.dev/docs/apps/auth/oauth) to create sessions for shops using your app.
The Shopify API gem tries to make this easy by providing functions to begin and complete the OAuth process. See the [Oauth doc](usage/oauth.md) for instructions on how to use these.

### Sessions

Sessions are required to make requests with the REST or GraphQL clients. This Library provides helpers for creating sessions via OAuth. Helpers are provided to retrieve session ID from a HTTP request from an embedded Shopify app or cookies from non-embedded apps.

Session persistence is handled by the [ShopifyApp](https://github.com/Shopify/shopify_app) gem and is recommended for use in the Rails context. See that gem for documentation on how to use it.

#### Cookie
Cookie based authentication is not supported for embedded apps due to browsers dropping support for third party cookies due to security concerns. Non-embedded apps are able to use cookies for session storage/retrieval.

For *non-embedded* apps, you can pass the cookies into:
 - `ShopifyAPI::Utils::SessionUtils.current_session_id(nil, cookies, true)` for online (user) sessions or
 - `ShopifyAPI::Utils::SessionUtils.current_session_id(nil, cookies, false)` for offline (store) sessions.

#### Getting Session ID From Embedded Requests

If your app uses client side rendering instead of server side rendering, you will need to use App Bridge's [authenticatedFetch](https://shopify.dev/docs/apps/auth/oauth/session-tokens/getting-started) to make authenticated API requests from the client.

For *embedded* apps:

If you have an `HTTP_AUTHORIZATION` header or `id_token` from the request URL params , you can pass that as `shopify_id_token` into:
- `ShopifyAPI::Utils::SessionUtils.current_session_id(shopify_id_token, nil, true)` for online (user) sessions or
- `ShopifyAPI::Utils::SessionUtils.current_session_id(shopify_id_token, nil, false)` for offline (store) sessions.

`current_session_id` accepts shopify_id_token in the format of `Bearer this_token` or just `this_token`.

You can also use this method to get session ID:
- `ShopifyAPI::Utils::SessionUtils::session_id_from_shopify_id_token(id_token: id_token, online: true)` for online (user) sessions or
- `ShopifyAPI::Utils::SessionUtils::session_id_from_shopify_id_token(id_token: id_token, online: false)` for offline (store) sessions.

`session_id_from_shopify_id_token` does **NOT** accept shopify_id_token in the format of `Bearer this_token`, you must pass in `this_token`.

#### Start Making Authenticated Shopify Requests

You can now start making authenticated Shopify API calls using the Admin [REST](usage/rest.md) or [GraphQL](usage/graphql.md) Clients or the [Storefront GraphQL Client](usage/graphql_storefront.md).

### Register Webhooks and a Webhook Handler

If you intend to use webhooks in your application follow the steps in the [Webhooks doc](usage/webhooks.md) for instructions on registering and handling webhooks.

