# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Treasury
    class DebitReversalService < StripeService
      # Reverses a ReceivedDebit and creates a DebitReversal object.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/treasury/debit_reversals",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of DebitReversals.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/treasury/debit_reversals",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves a DebitReversal object.
      def retrieve(debit_reversal, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/treasury/debit_reversals/%<debit_reversal>s", { debit_reversal: CGI.escape(debit_reversal) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
