# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class ReceivedDebitService < StripeService
      # Returns a list of ReceivedDebits.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/received_debits",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing ReceivedDebit by passing the unique ReceivedDebit ID from the ReceivedDebit list
      def retrieve(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/received_debits/%<id>s", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
