# Make a Storefront API call

The library also allows you to send GraphQL requests to the [Shopify Storefront API](https://shopify.dev/docs/api/storefront). To do that, you can use `ShopifyAPI::Clients::Graphql::Storefront` with either a [private or public Storefront access token](https://shopify.dev/docs/api/usage/authentication#access-tokens-for-the-storefront-api).

You can obtain Storefront API access tokens for both private apps and sales channels. Please read [our documentation](https://shopify.dev/docs/custom-storefronts/building-with-the-storefront-api/getting-started) to learn more about Storefront Access Tokens.

Below is an example of how you may query the Storefront API:

```ruby
# Load the access token as per instructions above
storefront_private_access_token = ''
# your shop domain
shop_url = 'shop.myshopify.com'

# initialize the client with session and a private Storefront access token
client = ShopifyAPI::Clients::Graphql::Storefront.new(shop_url, private_token: storefront_private_access_token)
# or, alternatively with a public Storefront access token:
# client = ShopifyAPI::Clients::Graphql::Storefront.new(shop_url, public_token: storefront_public_access_token)

query = <<~QUERY
  {
    collections(first: 2) {
      edges {
        node {
          id
          products(first: 5) {
            edges {
              node {
                id
                title
              }
            }
          }
        }
      }
    }
  }
QUERY

# You may not need the "Shopify-Storefront-Buyer-IP" header, see its documentation: 
# https://shopify.dev/docs/api/usage/authentication#making-server-side-requests
response = client.query(query: query, headers: { "Shopify-Storefront-Buyer-IP": request.ip })
# do something with the returned data
```

By default, the client uses the API version configured in `ShopifyAPI`.  To use a different API version, set the optional `api_version` parameter.  To experiment with prerelease API features, use `"unstable"` for the API version.

```ruby
client = ShopifyAPI::Clients::Graphql::Storefront.new(shop_url,
  private_token: storefront_private_access_token,
  api_version: "unstable"
)
```

Want to make calls to the Admin API? Click [here](graphql.md)
