# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderCollectPaymentMethodParams < ::Stripe::RequestParams
      class CollectConfig < ::Stripe::RequestParams
        class Tipping < ::Stripe::RequestParams
          # Amount used to calculate tip suggestions on tipping selection screen for this transaction. Must be a positive integer in the smallest currency unit (e.g., 100 cents to represent $1.00 or 100 to represent ¥100, a zero-decimal currency).
          attr_accessor :amount_eligible

          def initialize(amount_eligible: nil)
            @amount_eligible = amount_eligible
          end
        end
        # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow.
        attr_accessor :allow_redisplay
        # Enables cancel button on transaction screens.
        attr_accessor :enable_customer_cancellation
        # Override showing a tipping selection screen on this transaction.
        attr_accessor :skip_tipping
        # Tipping configuration for this transaction.
        attr_accessor :tipping

        def initialize(
          allow_redisplay: nil,
          enable_customer_cancellation: nil,
          skip_tipping: nil,
          tipping: nil
        )
          @allow_redisplay = allow_redisplay
          @enable_customer_cancellation = enable_customer_cancellation
          @skip_tipping = skip_tipping
          @tipping = tipping
        end
      end
      # Configuration overrides for this collection, such as tipping, surcharging, and customer cancellation settings.
      attr_accessor :collect_config
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The ID of the PaymentIntent to collect a payment method for.
      attr_accessor :payment_intent

      def initialize(collect_config: nil, expand: nil, payment_intent: nil)
        @collect_config = collect_config
        @expand = expand
        @payment_intent = payment_intent
      end
    end
  end
end
