# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class AuthorizationReverseParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The amount to reverse from the authorization. If not provided, the full amount of the authorization will be reversed. This amount is in the authorization currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
      attr_accessor :reverse_amount

      def initialize(expand: nil, reverse_amount: nil)
        @expand = expand
        @reverse_amount = reverse_amount
      end
    end
  end
end
