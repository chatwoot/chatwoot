# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderProcessSetupIntentParams < ::Stripe::RequestParams
      class ProcessConfig < ::Stripe::RequestParams
        # Enables cancel button on transaction screens.
        attr_accessor :enable_customer_cancellation

        def initialize(enable_customer_cancellation: nil)
          @enable_customer_cancellation = enable_customer_cancellation
        end
      end
      # This field indicates whether this payment method can be shown again to its customer in a checkout flow. Stripe products such as Checkout and Elements use this field to determine whether a payment method can be shown as a saved payment method in a checkout flow.
      attr_accessor :allow_redisplay
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Configuration overrides for this setup, such as MOTO and customer cancellation settings.
      attr_accessor :process_config
      # The ID of the SetupIntent to process on the reader.
      attr_accessor :setup_intent

      def initialize(allow_redisplay: nil, expand: nil, process_config: nil, setup_intent: nil)
        @allow_redisplay = allow_redisplay
        @expand = expand
        @process_config = process_config
        @setup_intent = setup_intent
      end
    end
  end
end
