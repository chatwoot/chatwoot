# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class CreditBalanceSummaryService < StripeService
      # Retrieves the credit balance summary for a customer.
      def retrieve(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/billing/credit_balance_summary",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
