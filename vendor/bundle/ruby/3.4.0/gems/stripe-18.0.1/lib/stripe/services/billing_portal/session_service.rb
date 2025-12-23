# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module BillingPortal
    class SessionService < StripeService
      # Creates a session of the customer portal.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/billing_portal/sessions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
