# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class ConfirmationTokenService < StripeService
      # Creates a test mode Confirmation Token server side for your integration tests.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/test_helpers/confirmation_tokens",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
