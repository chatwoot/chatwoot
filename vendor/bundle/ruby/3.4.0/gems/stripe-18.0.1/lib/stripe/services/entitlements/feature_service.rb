# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    class FeatureService < StripeService
      # Creates a feature
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/entitlements/features",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieve a list of features
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/entitlements/features",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a feature
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/entitlements/features/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Update a feature's metadata or permanently deactivate it.
      def update(id, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/entitlements/features/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
