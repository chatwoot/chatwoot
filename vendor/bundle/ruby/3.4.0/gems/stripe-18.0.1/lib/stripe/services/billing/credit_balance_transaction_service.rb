# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class CreditBalanceTransactionService < StripeService
      # Retrieve a list of credit balance transactions.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/billing/credit_balance_transactions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a credit balance transaction.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/billing/credit_balance_transactions/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
