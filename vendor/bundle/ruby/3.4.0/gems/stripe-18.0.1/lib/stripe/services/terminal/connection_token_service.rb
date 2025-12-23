# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ConnectionTokenService < StripeService
      # To connect to a reader the Stripe Terminal SDK needs to retrieve a short-lived connection token from Stripe, proxied through your server. On your backend, add an endpoint that creates and returns a connection token.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/terminal/connection_tokens",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
