# Breaking change notice for version 15.0.0

## Removal of `ShopifyAPI::Webhooks::Handler`

The `ShopifyAPI::Webhooks::Handler` class has been removed in favor of `ShopifyAPI::Webhooks::WebhookHandler`. The `ShopifyAPI::Webhooks::WebhookHandler` class is now the recommended way to handle webhooks.

Make a module or class that includes or extends `ShopifyAPI::Webhooks::WebhookHandler` and implement the `handle` method which accepts the following named parameters: data: `WebhookMetadata`.

In v14, adding new fields to the callback would become a breaking change. To make this code more flexible, handlers will now receive an object that can be typed and extended.

`data` will have the following keys
- `topic`, `String` - The topic of the webhook
- `shop`, `String` - The shop domain of the webhook
- `body`, `T::Hash[String, T.untyped]`- The body of the webhook
- `webhook_id`, `String` - The id of the webhook event to [avoid duplicates](https://shopify.dev/docs/apps/webhooks/best-practices#ignore-duplicates)
- `api_version`, `String` - The api version of the webhook

### New implementation
```ruby
module WebhookHandler
  extend ShopifyAPI::Webhooks::WebhookHandler

  class << self
    def handle_webhook(data:)
      puts "Received webhook! topic: #{data.topic} shop: #{data.shop} body: #{data.body} webhook_id: #{data.webhook_id} api_version: #{data.api_version"
    end
  end
end
```

### Previous implementation
```ruby
module WebhookHandler
  include ShopifyAPI::Webhooks::Handler

  class << self
    def handle(topic:, shop:, body:)
      puts "Received webhook! topic: #{topic} shop: #{shop} body: #{body}"
    end
  end
end
```
