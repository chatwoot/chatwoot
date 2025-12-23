# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class AssociationFindParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Valid [PaymentIntent](https://stripe.com/docs/api/payment_intents/object) id
      attr_accessor :payment_intent

      def initialize(expand: nil, payment_intent: nil)
        @expand = expand
        @payment_intent = payment_intent
      end
    end
  end
end
