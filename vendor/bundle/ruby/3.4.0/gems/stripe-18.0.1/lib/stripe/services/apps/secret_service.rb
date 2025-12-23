# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Apps
    class SecretService < StripeService
      # Create or replace a secret in the secret store.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/apps/secrets",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Deletes a secret from the secret store by name and scope.
      def delete_where(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/apps/secrets/delete",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Finds a secret in the secret store by name and scope.
      def find(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/apps/secrets/find",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # List all secrets stored on the given scope.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/apps/secrets",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
