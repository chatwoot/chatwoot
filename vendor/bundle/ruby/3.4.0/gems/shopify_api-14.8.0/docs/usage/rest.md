# Make a REST API call
> [!WARNING]
> The Admin REST API has been deprecated. New apps should use the GraphQL Admin API. For more information see [All in on GraphQL](https://www.shopify.com/ca/partners/blog/all-in-on-graphql). New apps will be created with the config option `rest_disabled: true`. This will raise a `ShopifyAPI::Errors::DisabledResourceError` if you try to use the REST API.

Once OAuth is complete, we can use `ShopifyAPI`'s REST library to make authenticated API calls to the Shopify Admin API.
#### Required Session
Every API request requires a valid
[ShopifyAPI::Auth::Session](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/auth/session.rb).

To instantiate a session, we recommend you either use the `shopify_app` if working in Rails, or refer to our OAuth docs on constructing a session:
 - ["Custom Apps"](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/custom_apps.md) - documentation on how to create Session from a custom app API token.
 - ["Performing OAuth"](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/oauth.md) - documentation on how to create new sessions
 - [[ShopifyApp] - "Session"](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md) - documentation on session handling if you're using the [`ShopifyApp`](https://github.com/Shopify/shopify_app) gem.

#### There are 2 methods you can use to make REST API calls to Shopify:
- [Using REST Resources](#using-rest-resources)
  - Resource classes with similar syntax as `ActiveResource`, and follows our REST convention. Example:
  ``` ruby
  # Update product title
  product = ShopifyAPI::Product.find(id: <product_id>)
  product.title = "My awesome product"
  product.save!
  ```

- [Using REST Admin Client](#using-rest-admin-client)
  - More manual input method to make the API call. Example:
  ```ruby
  # Create a new client.
  rest_client = ShopifyAPI::Clients::Rest::Admin.new

  # Update product title
  body = {
    product: {
      title: "My cool product"
    }
  }

  # Use `client.put` to send your request to the specified Shopify Admin REST API endpoint.
  rest_client.put(path: "products/<id>.json", body: body)
  ```

## Using REST Resources
We provide a templated class library to access REST resources similar to `ActiveResource`. Format of the methods closely resemble our [REST API schema](https://shopify.dev/docs/api/admin-rest).

The version of REST resource that's loaded and used is set from [`ShopifyAPI::Context.setup`](https://github.com/Shopify/shopify-api-ruby/blob/main/README.md#setup-shopify-context)

### Instantiation
Create an instance of the REST resource you'd like to use and optionally provide the following parameters.
#### Constructor parameters
| Parameter | Type | Notes |
| ----------|------|-------|
| `session` | `ShopifyAPI::Auth::Session` | Default value is `nil`. <br><br>When `nil` is passed in, active session information is inferred from `ShopifyAPI::Context.active_session`. <br>To set active session, use `ShopifyAPI::Context.activate_session`. <br><br>This is handled automatically behind the scenes if you use ShopifyApp's [session controllers](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md). |
| `from_hash` | `Hash` |  Default value is `nil`. Sets the resource properties to the values provided from the hash. |

Examples:

```ruby
# To construct an Orders object using default session
# This creates a new order object with properties provided from the hash
order = ShopifyAPI::Orders.new(from_hash: {property: value})
order.save!
```

### Methods
Typical methods provided for each resources are:
- `find`
- `delete`
- `all`
- `count`

Full list of methods can be found on each of the resource class.
- Path:
  - https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/rest/resources/#{version}/#{resource}.rb
- Example for `Order` resource on `2024-01` version:
  - https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/rest/resources/2024_01/order.rb

### The `save` method

The `save` or `save!` method on a resource allows you to `create` or `update` that resource.

#### Create a new resource

To create a new resource using the `save` or `save!` method, you can initialize the resource with a hash of values or simply assigning them manually. For example:

```Ruby
# Create a new product from hash
product_properties = {
  title: "My awesome product"
}
product = ShopifyAPI::Product.new(from_hash: product_properties)
product.save!

# Create a new product manually
product = ShopifyAPI::Product.new
product.title = "Another one"
product.save!
```

#### Update an existing resource

To update an existing resource using the `save` or `save!` method, you'll need to fetch the resource from Shopify first. Then, you can manually assign new values to the resource before calling `save` or `save!`. For example:

```Ruby
# Update a product's title
product = ShopifyAPI::Product.find(id: product_id)
product.title = "My new title"
product.save!

# Remove a line item from a draft order
draft_order = ShopifyAPI::DraftOrder.find(id: draft_order_id)

new_line_items = draft_order.line_items.reject { |line_item| line_item["id"] == 12345 }
draft_order.line_items = new_line_items

draft_order.save!
```

> [!IMPORTANT]
> If you need to unset an existing value,
> please explicitly set that attribute to `nil` or empty values such as `[]` or `{}`. For example:
>
> ```Ruby
>   # Removes shipping address from draft_order
>   draft_order.shipping_address = {}
>   draft_order.save!
> ```
>
> This is because only modified values are sent to the API, so if `shipping_address` is not "modified" to `{}`. It won't be part of the PUT request payload

When updating a resource, only the modified attributes, the resource's primary key, and required parameters are sent to the API. The primary key is usually the `id` attribute of the resource, but it can vary if the `primary_key` method is overwritten in the resource's class. The required parameters are identified using the path parameters of the `PUT` endpoint of the resource.

### Headers
You can add custom headers to the HTTP calls made by methods like `find`, `delete`, `all`, `count`
by setting the `headers` attribute on the `ShopifyAPI::Rest::Base` class in an initializer, like so:

```ruby
ShopifyAPI::Rest::Base.headers = { "X-Custom-Header" => "Custom Value" }
# `find` will call the API endpoint with the custom header
ShopifyAPI::Customer.find(id: customer_id)
```

### Usage Examples
⚠️ The [API reference documentation](https://shopify.dev/docs/api/admin-rest) contains more examples on how to use each REST Resources.

```Ruby
# Find and update a customer email
customer = ShopifyAPI::Customer.find(id: customer_id)
customer.email = "steve-lastnameson@example.com"
customer.save!

# Get all orders
orders = ShopifyAPI::Orders.all

# Retrieve a specific fulfillment order
fulfillment_order_id = 123456789
fulfillment_order = ShopifyAPI::FulfillmentOrder.find(id: fulfillment_order_id)

# Remove an existing product image
product_id = 1234567
image_id = 1233211234567
ShopifyAPI::Image.delete(product_id: product_id, id: image_id)
```

More examples can be found in each resource's documentation on [shopify.dev](https://shopify.dev/docs/api/admin-rest), e.g.:
- [Order](https://shopify.dev/docs/api/admin-rest/current/resources/order)
- [Product](https://shopify.dev/docs/api/admin-rest/current/resources/product)

## Using REST Admin Client

### Instantiation
Create an instance of [`ShopifyAPI::Clients::Rest::Admin`](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/clients/rest/admin.rb) using the current session to make requests to the Admin API.
#### Constructor parameters
| Parameter | Type | Notes |
| ----------|------|-------|
| `session` | `ShopifyAPI::Auth::Session` | Default value is `nil`. <br><br>When `nil` is passed in, active session information is inferred from `ShopifyAPI::Context.active_session`. <br>To set active session, use `ShopifyAPI::Context.activate_session`. <br><br>This is handled automatically behind the scenes if you use ShopifyApp's [session controllers](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md). |
| `api_version` | `String` | Default value is `nil`. When `nil` is passed in, api version is inferred from [`ShopifyAPI::Context.setup`](https://github.com/Shopify/shopify-api-ruby/blob/main/README.md#setup-shopify-context).|

Examples:
```ruby
# Create a default client with `ShopifyAPI::Context.api_version`
# and the active session from `ShopifyAPI::Context.active_session`
client = ShopifyAPI::Clients::Rest::Admin.new

# Create a client with a specific session "my_session"
client = ShopifyAPI::Clients::Rest::Admin.new(session: my_session)

# Create a client with active session from `ShopifyAPI::Context.active_session`
# and a specific api_version - "unstable"
client = ShopifyAPI::Clients::Rest::Admin.new(api_version: "unstable")

# Create a client with a specific session "my_session" and api_version "unstable"
client = ShopifyAPI::Clients::Rest::Admin.new(session: my_session, api_version: "unstable")
```

### Methods

The `ShopifyAPI::Clients::Rest::Admin` client offers the 4 core request methods:
- `get`
- `delete`
- `post`
- `put`

#### Input Parameters

Each method can take the parameters outlined in the table below.

| Parameter      | Type                                                     | Required in Methods | Default Value | Notes                                                                                                                                                                                                                                                                                  |
| -------------- | -------------------------------------------------------- | :-----------------: | :-----------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `path`         | `String`                                                 |         all         |     none      | The requested API endpoint path. This can be one of two formats:<ul><li>The path starting after the `/admin/api/{version}/` prefix, such as `products`, which executes `/admin/api/{version}/products.json`</li><li>The full path, such as `/admin/oauth/access_scopes.json`</li></ul> |
| `body`         | `Hash(any(Symbol, String), untyped)`                     |    `put`, `post`    |     none      | The body of the request                                                                                                                                                                                                                                                                |
| `query`        | `Hash(any(Symbol, String), any(String, Integer, Float))` |        none         |     none      | An optional query object to be appended to the request url as a query string                                                                                                                                                                                                           |
| `extraHeaders` | `Hash(any(Symbol, String), any(String, Integer, Float))` |        none         |     none      | Any additional headers you want to send with your request                                                                                                                                                                                                                              |
| `tries`        | `Integer`                                                |        None         |      `1`      | The maximum number of times to try the request _(must be >= 0)_                                                                                                                                                                                                                        |

**Note:** _These parameters can still be used in all methods regardless of if they are required._

#### Output
##### Success
If the request is successful these methods will all return a [`ShopifyAPI::Clients::HttpResponse`](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/clients/http_response.rb) object, which has the following methods:
| Methods | Type | Notes |
|---------|------|-------|
| `code`  |`Integer`| HTTP Response code, e.g. `200`|
| `headers` |`Hash{String, [String]}` | HTTP Response headers |
| `body`  | `Hash{String, Untyped}`  | HTTP Response body |
| `prev_page_info` | `String` | See [Pagination](#pagination)|
| `next_page_info` | `String` | See [Pagination](#pagination)|

##### Failure
If the request has failed, an error will be raised describing what went wrong.
You can rescue [`ShopifyAPI::Errors::HttpResponseError`](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/errors/http_response_error.rb)
and output error messages with `errors.full_messages`

See example:

```ruby
    client = ShopifyAPI::Clients::Rest::Admin.new(session: session)
    response = client.get(path: "NOT-REAL")
    some_function(response.body)
rescue ShopifyAPI::Errors::HttpResponseError => e
  puts fulfillment.errors.full_messages
  # {"errors"=>"Not Found"}
  # If you report this error, please include this id: bce76672-40c6-4047-b598-46208ab076f0.
```
### Usage Examples

#### Perform a `GET` request

```ruby
# Create a new client.
client = ShopifyAPI::Clients::Rest::Admin.new(session: session)

# Use `client.get` to request the specified Shopify REST API endpoint, in this case `products`.
response = client.get(path: "products")

# Do something with the returned data
some_function(response.body)
```
_For more information on the `products` endpoint, [check out our API reference guide](https://shopify.dev/docs/api/admin-rest/latest/resources/product)._

#### Perform a `POST` request

```ruby
# Create a new client.
client = ShopifyAPI::Clients::Rest::Admin.new(session: session)

# Build your post request body.
body = {
  product: {
    title: "Burton Custom Freestyle 151",
    body_html: "\u003cstrong\u003eGood snowboard!\u003c\/strong\u003e",
    vendor: "Burton",
    product_type: "Snowboard",
  }
}

# Use `client.post` to send your request to the specified Shopify Admin REST API endpoint.
# This POST request will create a new product.
client.post({
  path: "products",
  body: body,
});
```

_For more information on the `products` endpoint, [check out our API reference guide](https://shopify.dev/docs/api/admin-rest/latest/resources/product)._

#### Perform a `PUT` request
  ```ruby
  # Create a new client.
  client = ShopifyAPI::Clients::Rest::Admin.new

  # Update product title
  body = {
    product: {
      title: "My cool product"
    }
  }

  # Use `client.put` to send your request to the specified Shopify Admin REST API endpoint.
  # This will update product title for product with ID <id>
  client.put(path: "products/<id>.json", body: body)
```

_For more information on the `products` endpoint, [check out our API reference guide](https://shopify.dev/docs/api/admin-rest/latest/resources/product)._

#### Accessing Rate Limit information

The REST resources have `api_call_limit` and `retry_after` can be found on the Resource class. These values correspond to the `X-Shopify-Shop-Api-Call-Limit` and `Retry-After` [headers](https://shopify.dev/docs/api/usage/rate-limits#rest-admin-api-rate-limits) respectively.

```ruby
product = ShopifyAPI::Product.find(session: session, id: 12345)

# X-Shopify-Shop-Api-Call-Limit: 32/40
request_count = ShopifyAPI::Product.api_call_limit[:request_count] # 32
bucket_size = ShopifyAPI::Product.api_call_limit[:bucket_size] # 40

retry_after = ShopifyAPI::Product.retry_request_after

```

### Pagination

This library also supports cursor-based pagination for REST Admin API requests. [Learn more about REST request pagination](https://shopify.dev/docs/api/usage/pagination-rest).

#### REST Admin Client
After making a request, the `next_page_info` and `prev_page_info` can be found on the response object and passed as the `page_info` query param in other requests.

An example of this is shown below:

```ruby
client = ShopifyAPI::Clients::Rest::Admin.new(session: session)

response = client.get(path: "products", query: { limit: 10 })
next_page_info = response.next_page_info

if next_page_info
  next_page_response =client.get(path: "products", query: { limit: 10, page_info: next_page_info })
  some_function(next_page_response)
end
```

#### REST Resource
Similarly, when using REST resources the `next_page_info` and `prev_page_info` can be found on the Resource class and passed as the `page_info` query param in other requests.

An example of this is shown below:

```ruby
products = ShopifyAPI::Product.all(session: session, limit: 10)

loop do
  some_function(products)
  break unless ShopifyAPI::Product.next_page?
  products = ShopifyAPI::Product.all(session: session, limit: 10, page_info: ShopifyAPI::Product.next_page_info)
end
```

[Back to guide index](../README.md)
