# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class TransactionLineItemService < StripeService
      # Retrieves the line items of a committed standalone transaction as a collection.
      def list(transaction, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/tax/transactions/%<transaction>s/line_items", { transaction: CGI.escape(transaction) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
