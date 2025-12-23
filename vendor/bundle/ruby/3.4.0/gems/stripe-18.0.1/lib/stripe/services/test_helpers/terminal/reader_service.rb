# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Terminal
      class ReaderService < StripeService
        # Presents a payment method on a simulated reader. Can be used to simulate accepting a payment, saving a card or refunding a transaction.
        def present_payment_method(reader, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/present_payment_method", { reader: CGI.escape(reader) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Use this endpoint to trigger a successful input collection on a simulated reader.
        def succeed_input_collection(reader, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/succeed_input_collection", { reader: CGI.escape(reader) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end

        # Use this endpoint to complete an input collection with a timeout error on a simulated reader.
        def timeout_input_collection(reader, params = {}, opts = {})
          request(
            method: :post,
            path: format("/v1/test_helpers/terminal/readers/%<reader>s/timeout_input_collection", { reader: CGI.escape(reader) }),
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
