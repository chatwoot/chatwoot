# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class TransactionRefundParams < ::Stripe::RequestParams
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # The total amount to attempt to refund. This amount is in the provided currency, or defaults to the cards currency, and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_accessor :refund_amount

        def initialize(expand: nil, refund_amount: nil)
          @expand = expand
          @refund_amount = refund_amount
        end
      end
    end
  end
end
