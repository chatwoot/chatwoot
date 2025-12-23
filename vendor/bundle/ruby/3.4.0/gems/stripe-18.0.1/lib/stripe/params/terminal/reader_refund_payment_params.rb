# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderRefundPaymentParams < ::Stripe::RequestParams
      class RefundPaymentConfig < ::Stripe::RequestParams
        # Enables cancel button on transaction screens.
        attr_accessor :enable_customer_cancellation

        def initialize(enable_customer_cancellation: nil)
          @enable_customer_cancellation = enable_customer_cancellation
        end
      end
      # A positive integer in __cents__ representing how much of this charge to refund.
      attr_accessor :amount
      # ID of the Charge to refund.
      attr_accessor :charge
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # ID of the PaymentIntent to refund.
      attr_accessor :payment_intent
      # Boolean indicating whether the application fee should be refunded when refunding this charge. If a full charge refund is given, the full application fee will be refunded. Otherwise, the application fee will be refunded in an amount proportional to the amount of the charge refunded. An application fee can be refunded only by the application that created the charge.
      attr_accessor :refund_application_fee
      # Configuration overrides for this refund, such as customer cancellation settings.
      attr_accessor :refund_payment_config
      # Boolean indicating whether the transfer should be reversed when refunding this charge. The transfer will be reversed proportionally to the amount being refunded (either the entire or partial amount). A transfer can be reversed only by the application that created the charge.
      attr_accessor :reverse_transfer

      def initialize(
        amount: nil,
        charge: nil,
        expand: nil,
        metadata: nil,
        payment_intent: nil,
        refund_application_fee: nil,
        refund_payment_config: nil,
        reverse_transfer: nil
      )
        @amount = amount
        @charge = charge
        @expand = expand
        @metadata = metadata
        @payment_intent = payment_intent
        @refund_application_fee = refund_application_fee
        @refund_payment_config = refund_payment_config
        @reverse_transfer = reverse_transfer
      end
    end
  end
end
