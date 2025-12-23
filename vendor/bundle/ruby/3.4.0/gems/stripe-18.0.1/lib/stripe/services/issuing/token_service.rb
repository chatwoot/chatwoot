# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class TokenService < StripeService
      # Lists all Issuing Token objects for a given card.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/tokens",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an Issuing Token object.
      def retrieve(token, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/tokens/%<token>s", { token: CGI.escape(token) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Attempts to update the specified Issuing Token object to the status specified.
      def update(token, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/tokens/%<token>s", { token: CGI.escape(token) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
