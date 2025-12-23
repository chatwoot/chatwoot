# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class TransactionService < StripeService
        # Allows the user to capture an arbitrary amount, also known as a forced capture.
        def create_force_capture(params = {}, opts = {})
          request(
            method: :post,
            path: "/v1/test_helpers/issuing/transactions/create_force_capture",
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Allows the user to refund an arbitrary amount, also known as a unlinked refund.
        def create_unlinked_refund(params = {}, opts = {})
          request(
            method: :post,
            path: "/v1/test_helpers/issuing/transactions/create_unlinked_refund",
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Refund a test-mode Transaction.
        def refund(transaction, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/issuing/transactions/%<transaction>s/refund", { transaction: CGI.escape(transaction) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
