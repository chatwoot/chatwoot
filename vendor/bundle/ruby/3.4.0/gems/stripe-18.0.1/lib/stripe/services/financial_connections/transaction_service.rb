# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class TransactionService < StripeService
      # Returns a list of Financial Connections Transaction objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/financial_connections/transactions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of a Financial Connections Transaction
      def retrieve(transaction, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/financial_connections/transactions/%<transaction>s", { transaction: CGI.escape(transaction) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
