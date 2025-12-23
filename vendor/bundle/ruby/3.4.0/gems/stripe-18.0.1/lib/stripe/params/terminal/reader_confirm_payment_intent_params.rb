# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderConfirmPaymentIntentParams < ::Stripe::RequestParams
      class ConfirmConfig < ::Stripe::RequestParams
        # The URL to redirect your customer back to after they authenticate or cancel their payment on the payment method's app or site. If you'd prefer to redirect to a mobile application, you can alternatively supply an application URI scheme.
        attr_accessor :return_url

        def initialize(return_url: nil)
          @return_url = return_url
        end
      end
      # Configuration overrides for this confirmation, such as surcharge settings and return URL.
      attr_accessor :confirm_config
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The ID of the PaymentIntent to confirm.
      attr_accessor :payment_intent

      def initialize(confirm_config: nil, expand: nil, payment_intent: nil)
        @confirm_config = confirm_config
        @expand = expand
        @payment_intent = payment_intent
      end
    end
  end
end
