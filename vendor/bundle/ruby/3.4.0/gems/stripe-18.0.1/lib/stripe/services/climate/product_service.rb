# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    class ProductService < StripeService
      # Lists all available Climate product objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/climate/products",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of a Climate product with the given ID.
      def retrieve(product, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/climate/products/%<product>s", { product: CGI.escape(product) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
