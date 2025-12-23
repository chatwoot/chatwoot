# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class TransactionService < StripeService
      # Retrieves a list of Transaction objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/transactions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing Transaction.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/transactions/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
