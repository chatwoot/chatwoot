# Make a GraphQL API call

Once OAuth is complete, we can use `ShopifyAPI::Clients::Graphql::Admin` to make authenticated API calls to the Shopify Admin GraphQL API.
#### Required Session
Every API request requires a valid
[ShopifyAPI::Auth::Session](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/auth/session.rb).

To instantiate a session, we recommend you either use the `shopify_app` if working in Rails, or refer to our OAuth docs on constructing a session:
 - ["Custom Apps"](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/custom_apps.md) - documentation on how to create Session from a custom app API token.
 - ["Performing OAuth"](https://github.com/Shopify/shopify-api-ruby/blob/main/docs/usage/oauth.md) - documentation on how to create new sessions
 - [[ShopifyApp] - "Session"](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md) - documentation on session handling if you're using the [`ShopifyApp`](https://github.com/Shopify/shopify_app) gem.

### Instantiation
Create an instance of [`ShopifyAPI::Clients::Graphql::Admin`](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/clients/graphql/admin.rb) using the current session to make requests to the Admin API.

#### Constructor parameters
| Parameter | Type | Notes |
| ----------|------|-------|
| `session` | `ShopifyAPI::Auth::Session` | Default value is `nil`. <br><br>When `nil` is passed in, active session information is inferred from `ShopifyAPI::Context.active_session`. <br>To set active session, use `ShopifyAPI::Context.activate_session`. <br><br>This is handled automatically behind the scenes if you use ShopifyApp's [session controllers](https://github.com/Shopify/shopify_app/blob/main/docs/shopify_app/sessions.md). |
| `api_version` | `String` | Default value is `nil`. When `nil` is passed in, api version is inferred from [`ShopifyAPI::Context.setup`](https://github.com/Shopify/shopify-api-ruby/blob/main/README.md#setup-shopify-context).|

Usage:
```ruby
client = ShopifyAPI::Clients::Graphql::Admin.new(session: session, api_version: "unstable")
```

### Making Authenticated API calls
#### Basic example

```ruby
# Initialize the client
client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)

# Make the GraphQL query string
query =<<~QUERY
  {
    products(first: 10) {
      edges {
        cursor
        node {
          id
          title
          onlineStoreUrl
        }
      }
    }
  }
QUERY

response = client.query(query: query)

# do something with the response data
product = response.body["data"]["products"]["edges"][0]
my_function(product)
```

#### Example GraphQL query with variables

```ruby
client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)

query = <<~QUERY
  query testQueryWithVariables($first: Int!){
    products(first: $first) {
      edges {
        cursor
        node {
          id
          title
          onlineStoreUrl
        }
      }
    }
  }
QUERY

variables = {
  first: 3
}

response = client.query(query: query, variables: variables)
```

#### Example GraphQL query with fragments

```ruby
client = ShopifyAPI::Clients::Graphql::Admin.new(session: session)

# define the fragment as part of the query
query = <<~QUERY
  fragment ProductStuff on Product {
    id
    title
    description
    onlineStoreUrl
  }
  query testQueryWithVariables($first: Int){
    products(first: $first) {
      edges {
        cursor
        node {
          ...ProductStuff
        }
      }
    }
  }
QUERY

variables = {
  first: 3
}

response = client.query(query: query, variables: variables)
# do something with the response
```


### Output
#### Success
If the request is successful these methods will all return a [`ShopifyAPI::Clients::HttpResponse`](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/clients/http_response.rb) object, which has the following methods:
| Methods | Type | Notes |
|---------|------|-------|
| `code`  |`Integer`| HTTP Response code, e.g. `200`|
| `header` |`Hash{String, [String]}` | HTTP Response headers |
| `body`  | `Hash{String, Untyped}`  | HTTP Response body |
| `prev_page_info` | `String` | See [Pagination](#pagination)|
| `next_page_info` | `String` | See [Pagination](#pagination)|

#### Failure
If the request has failed, an error will be raised describing what went wrong.
You can rescue [`ShopifyAPI::Errors::HttpResponseError`](https://github.com/Shopify/shopify-api-ruby/blob/main/lib/shopify_api/errors/http_response_error.rb)
and output error messages with `errors.full_messages`

## Pagination

This library also supports cursor-based pagination for GraphQL Admin API requests. [Learn more about GraphQL request pagination](https://shopify.dev/docs/api/usage/pagination-graphql).

After making a request, the `next_page_info` and `prev_page_info` can be found on the response object and be used in the query param in other requests.

## Response as Struct
By default the response body is returned as a `Hash{String, Untyped}`. If you would like to return the response body as a `Struct`, you can pass `response_as_struct: true` to the `ShopifyAPI::Context.setup` method.
Then you can access the object with both dot and hash notation.

```ruby
    ShopifyAPI::Context.setup(
      api_key: ShopifyApp.configuration.api_key,
      api_secret_key: ShopifyApp.configuration.secret,
      ...
      response_as_struct: true
    )

    # Make a graphql query
      response = client.query(
        query: CREATE_PRODUCTS_MUTATION,
        variables: {
          input: {
            title: random_title,
            variants: [{ price: random_price }],
          },
        },
      )
      # Access result with dot notation
      created_product2 = response.body.data.productCreate.product
      # Access result with hash notation
      created_product = response.body["data"]["productCreate"]["product"]

```

## Proxy a GraphQL Query

If you would like to give your front end the ability to make authenticated graphql queries to the Shopify Admin API, the `shopify_api` gem makes proxy-ing a graphql request easy! The gem provides a utility function which will accept the raw request body (a GraphQL query), the headers, and the cookies (optional). It will add authentication to the request, proxy it to the Shopify Admin API, and return a `ShopifyAPI::Clients::HttpResponse`. An example utilization of this in Rails is shown below:

```ruby
def proxy
  begin
    response = ShopifyAPI::Utils::GraphqlProxy.proxy_query(
      session: session,
      headers: request.headers.to_h,
      body: request.raw_post,
      cookies: request.cookies.to_h
    )

    render json: response.body, status: response.code
  rescue ShopifyAPI::Errors::InvalidGraphqlRequestError
    # Handle bad request
  rescue ShopifyAPI::Errors::SessionNotFoundError
    # Handle no session found
  end
end
```

**Note:** GraphQL proxying is only supported for online sessions for non-private apps, the utility will raise a `ShopifyAPI::Errors::SessionNotFoundError` if there are no existing online tokens for the provided credentials, and a `ShopifyAPI::Errors::PrivateAppError` if called from a private app.

## Storefront API
⚠️ Want to make calls to the Storefront API? [Read this](graphql_storefront.md).
