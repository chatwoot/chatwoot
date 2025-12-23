# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class AssociationService < StripeService
      # Finds a tax association object by PaymentIntent id.
      def find(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/tax/associations/find",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
