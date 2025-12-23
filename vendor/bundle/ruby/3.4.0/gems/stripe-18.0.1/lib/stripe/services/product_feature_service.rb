# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ProductFeatureService < StripeService
    # Creates a product_feature, which represents a feature attachment to a product
    def create(product, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/products/%<product>s/features", { product: CGI.escape(product) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Deletes the feature attachment to a product
    def delete(product, id, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/products/%<product>s/features/%<id>s", { product: CGI.escape(product), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieve a list of features for a product
    def list(product, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/products/%<product>s/features", { product: CGI.escape(product) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves a product_feature, which represents a feature attachment to a product
    def retrieve(product, id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/products/%<product>s/features/%<id>s", { product: CGI.escape(product), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
