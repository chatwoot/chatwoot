# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ProductService < StripeService
    attr_reader :features

    def initialize(requestor)
      super
      @features = Stripe::ProductFeatureService.new(@requestor)
    end

    # Creates a new product object.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/products", params: params, opts: opts, base_address: :api)
    end

    # Delete a product. Deleting a product is only possible if it has no prices associated with it. Additionally, deleting a product with type=good is only possible if it has no SKUs associated with it.
    def delete(id, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/products/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your products. The products are returned sorted by creation date, with the most recently created products appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/products", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an existing product. Supply the unique product ID from either a product creation request or the product list, and Stripe will return the corresponding product information.
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/products/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Search for products you've previously created using Stripe's [Search Query Language](https://docs.stripe.com/docs/search#search-query-language).
    # Don't use search in read-after-write flows where strict consistency is necessary. Under normal operating
    # conditions, data is searchable in less than a minute. Occasionally, propagation of new or updated data can be up
    # to an hour behind during outages. Search functionality is not available to merchants in India.
    def search(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/products/search",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specific product by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    def update(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/products/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
