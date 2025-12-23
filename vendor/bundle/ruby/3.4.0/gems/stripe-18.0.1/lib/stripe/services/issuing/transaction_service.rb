# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class TransactionService < StripeService
      # Returns a list of Issuing Transaction objects. The objects are sorted in descending order by creation date, with the most recently created object appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/issuing/transactions",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an Issuing Transaction object.
      def retrieve(transaction, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/issuing/transactions/%<transaction>s", { transaction: CGI.escape(transaction) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Updates the specified Issuing Transaction object by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
      def update(transaction, params = {}, opts = {})
        request(
          method: :post,
          path: format("/v1/issuing/transactions/%<transaction>s", { transaction: CGI.escape(transaction) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
