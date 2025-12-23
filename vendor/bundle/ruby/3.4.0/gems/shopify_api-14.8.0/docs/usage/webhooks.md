# Webhooks

The `shopify_api` gem provides webhook functionality to make it easy to both subscribe to and process webhooks. To implement in your app follow the steps outlined below.

## Use with Rails
If using in the Rails framework, we highly recommend you use the [shopify_app](https://github.com/Shopify/shopify_app) gem to interact with this gem. That gem handles [webhooks with a declarative configuration](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/webhooks.md).

## Create a Webhook Handler

If you want to register for an http webhook you need to implement a webhook handler which the `shopify_api` gem can use to determine how to process your webhook. You can make multiple implementations (one per topic) or you can make one implementation capable of handling all the topics you want to subscribe to. To do this simply make a module or class that includes or extends `ShopifyAPI::Webhooks::WebhookHandler` and implement the `handle` method which accepts the following named parameters: data: `WebhookMetadata`. An example implementation is shown below:

`data` will have the following keys
- `topic`, `String` - The topic of the webhook
- `shop`, `String` - The shop domain of the webhook
- `body`, `T::Hash[String, T.untyped]`- The body of the webhook
- `webhook_id`, `String` - The id of the webhook event to [avoid duplicates](https://shopify.dev/docs/apps/webhooks/best-practices#ignore-duplicates)
- `api_version`, `String` - The api version of the webhook

```ruby
module WebhookHandler
  extend ShopifyAPI::Webhooks::WebhookHandler

  class << self
    def handle(data:)
      puts "Received webhook! topic: #{data.topic} shop: #{data.shop} body: #{data.body} webhook_id: #{data.webhook_id} api_version: #{data.api_version}"
      perform_later(topic: data.topic, shop_domain: data.shop, webhook: data.body)
    end
  end
end
```

**Note:** As of version 13.5.0 the `ShopifyAPI::Webhooks::Handler` class is still available to be used but will be removed in a future version of the gem.

### Best Practices
It is recommended that in order to respond quickly to the Shopify webhook request that the handler not do any heavy logic or network calls, rather it should simply enqueue the work in some job queue in order to be executed later.

### Webhook Handler for versions 13.4.0 and prior
If you want to register for an http webhook you need to implement a webhook handler which the `shopify_api` gem can use to determine how to process your webhook. You can make multiple implementations (one per topic) or you can make one implementation capable of handling all the topics you want to subscribe to. To do this simply make a module or class that includes or extends `ShopifyAPI::Webhooks::Handler` and implement the handle method which accepts the following named parameters: topic: `String`, shop: `String`, and body: `Hash[String, untyped]`. An example implementation is shown below:

```ruby
module WebhookHandler
  extend ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      puts "Received webhook! topic: #{topic} shop: #{shop} body: #{body}"
    end
  end
end
```

## Add to Webhook Registry

The next step is to add all the webhooks you would like to subscribe to for any shop to the webhook registry. To do this you can call `ShopifyAPI::Webhooks::Registry.add_registration` for each webhook you would like to handle. `add_registration` accepts a topic string, a delivery_method symbol (currently supporting `:http`, `:event_bridge`, and `:pub_sub`), a webhook path (the relative path for an http webhook) and a handler. This only needs to be done once when the app is started and we recommend doing this at the same time that you setup `ShopifyAPI::Context`. An example is shown below to register an http webhook:

```ruby
registration = ShopifyAPI::Webhooks::Registry.add_registration(topic: "orders/create",
                                                               delivery_method: :http,
                                                               handler: WebhookHandler,
                                                               path: 'callback/orders/create')
```
If you are only interested in particular fields, you can optionally filter the data sent by Shopify by specifying the `fields` parameter. Note that you will still receive a webhook request from Shopify every time the resource is updated, but only the specified fields will be sent:

```ruby
registration = ShopifyAPI::Webhooks::Registry.add_registration(
  topic: "orders/create",
  delivery_method: :http,
  handler: WebhookHandler,
  path: 'callback/orders/create',
  fields: ["number","note"] # this can also be a single comma separated string
)
```

If you are storing metafields on an object you are receiving webhooks for, you can specify them on registration to make sure that they are also sent through the `metafieldNamespaces` parameter. Note if you are also using the `fields` parameter you will need to add `metafields` into that as well.

```ruby
registration = ShopifyAPI::Webhooks::Registry.add_registration(
  topic: "orders/create",
  delivery_method: :http,
  handler: WebhookHandler,
  metafieldNamespaces: ["custom"]
)
```

If you need to filter the webhooks you want to receive, you can use a [webhooks filter](https://shopify.dev/docs/apps/build/webhooks/customize/filters), which can be specified on registration through the `filter` parameter.

```ruby
registration = ShopifyAPI::Webhooks::Registry.add_registration(
  topic: "products/update",
  delivery_method: :http,
  handler: WebhookHandler,
  filter: "variants.price:>=10.00"
)
```

**Note**: The webhooks you register with Shopify are saved in the Shopify platform, but the local `ShopifyAPI::Webhooks::Registry` needs to be reloaded whenever your server restarts.

### EventBridge and PubSub Webhooks

You can also register webhooks for delivery to Amazon EventBridge or Google Cloud
Pub/Sub. In this case the `path` argument to
`Shopify.Webhooks.Registry.register` needs to be of a specific form.

For EventBridge, the `path` must be the [ARN of the partner event
source](https://docs.aws.amazon.com/eventbridge/latest/APIReference/API_EventSource.html).

For Pub/Sub, the `path` must be of the form
`pubsub://[PROJECT-ID]:[PUB-SUB-TOPIC-ID]`. For example, if you created a topic
with id `red` in the project `blue`, then the value of `path` would be
`pubsub://blue:red`.

When registering for an EventBridge or PubSub Webhook you do not need to specify a handler as this is only used for handling Http webhooks.

## Register a Webhook for a Shop
At any point that you have a session for a shop you can register to receive webhooks for that shop. We recommend registering for webhooks immediately after [OAuth](./oauth.md).

This can be done in one of two ways:

If you would like to register to receive webhooks for all topics you have added to the registry for a specific shop you can simply call:
```ruby
ShopifyAPI::Webhooks::Registry.register_all(session: shop_session)
```

This will return an Array of `ShopifyAPI::Webhooks::RegisterResult`s that have fields `topic`, `success`, and `body` which can be used to see which webhooks were successfully registered.

Or if you would like to register to receive webhooks for specific topics that have been added to the registry for a specific shop you can simply call `register` for any needed topics:
```ruby
ShopifyAPI::Webhooks::Registry.register(topic: "<specific-topic>", session: shop_session)
```

This will return a single `ShopifyAPI::Webhooks::RegisterResult`.

## Unregister a Webhook

To unregister a topic from a shop you can simply call:
```ruby
ShopifyAPI::Webhooks::Registry.unregister(topic: "orders/create", session: shop_session)
```

## Process a Webhook

To process an http webhook, you need to listen on the route(s) you provided during the Webhook registration process, then when the route is hit construct a `ShopifyAPI::Webhooks::Request` and call `ShopifyAPI::Webhooks::Registry.process`. This will verify the request did indeed come from Shopify and then call the specified handler for that webhook. An example in Rails is shown below:

```ruby
class WebhookController < ApplicationController
  def webhook
    ShopifyAPI::Webhooks::Registry.process(
      ShopifyAPI::Webhooks::Request.new(raw_body: request.raw_post, headers: request.headers.to_h)
    )
    render json: {success: true}.to_json
  end
end
```
