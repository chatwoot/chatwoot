# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class TransactionService < StripeService
      attr_reader :line_items

      def initialize(requestor)
        super
        @line_items = Stripe::Tax::TransactionLineItemService.new(@requestor)
      end

      # Creates a Tax Transaction from a calculation, if that calculation hasn't expired. Calculations expire after 90 days.
      def create_from_calculation(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/tax/transactions/create_from_calculation",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Partially or fully reverses a previously created Transaction.
      def create_reversal(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/tax/transactions/create_reversal",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a Tax Transaction object.
      def retrieve(transaction, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/tax/transactions/%<transaction>s", { transaction: CGI.escape(transaction) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
