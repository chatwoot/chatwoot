# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PriceService < StripeService
    # Creates a new [Price for an existing <a href="https://docs.stripe.com/api/products">Product](https://docs.stripe.com/api/prices). The Price can be recurring or one-time.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/prices", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of your active prices, excluding [inline prices](https://docs.stripe.com/docs/products-prices/pricing-models#inline-pricing). For the list of inactive prices, set active to false.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/prices", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the price with the given ID.
    def retrieve(price, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/prices/%<price>s", { price: CGI.escape(price) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Search for prices you've previously created using Stripe's [Search Query Language](https://docs.stripe.com/docs/search#search-query-language).
    # Don't use search in read-after-write flows where strict consistency is necessary. Under normal operating
    # conditions, data is searchable in less than a minute. Occasionally, propagation of new or updated data can be up
    # to an hour behind during outages. Search functionality is not available to merchants in India.
    def search(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/prices/search",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified price by setting the values of the parameters passed. Any parameters not provided are left unchanged.
    def update(price, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/prices/%<price>s", { price: CGI.escape(price) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
