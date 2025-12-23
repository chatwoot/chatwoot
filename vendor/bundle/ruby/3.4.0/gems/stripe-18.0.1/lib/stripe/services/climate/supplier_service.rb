# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Climate
    class SupplierService < StripeService
      # Lists all available Climate supplier objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/climate/suppliers",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a Climate supplier object.
      def retrieve(supplier, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/climate/suppliers/%<supplier>s", { supplier: CGI.escape(supplier) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
