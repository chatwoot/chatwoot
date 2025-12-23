# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderProcessPaymentIntentParams < ::Stripe::RequestParams
      class ProcessConfig < ::Stripe::RequestParams
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
        # The URL to redirect your customer back to after they authenticate or cancel their payment on the payment method's app or site. If you'd prefer to redirect to a mobile application, you can alternatively supply an application URI scheme.
        attr_accessor :return_url
        # Override showing a tipping selection screen on this transaction.
        attr_accessor :skip_tipping
        # Tipping configuration for this transaction.
        attr_accessor :tipping

        def initialize(
          allow_redisplay: nil,
          enable_customer_cancellation: nil,
          return_url: nil,
          skip_tipping: nil,
          tipping: nil
        )
          @allow_redisplay = allow_redisplay
          @enable_customer_cancellation = enable_customer_cancellation
          @return_url = return_url
          @skip_tipping = skip_tipping
          @tipping = tipping
        end
      end
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The ID of the PaymentIntent to process on the reader.
      attr_accessor :payment_intent
      # Configuration overrides for this transaction, such as tipping and customer cancellation settings.
      attr_accessor :process_config

      def initialize(expand: nil, payment_intent: nil, process_config: nil)
        @expand = expand
        @payment_intent = payment_intent
        @process_config = process_config
      end
    end
  end
end
