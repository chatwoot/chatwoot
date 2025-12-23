# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class TransactionEntryService < StripeService
      # Retrieves a list of TransactionEntry objects.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/transaction_entries",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a TransactionEntry object.
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/transaction_entries/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
