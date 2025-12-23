# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    module Issuing
      class AuthorizationIncrementParams < ::Stripe::RequestParams
        # Specifies which fields in the response should be expanded.
        attr_accessor :expand
        # The amount to increment the authorization by. This amount is in the authorization currency and in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal).
        attr_accessor :increment_amount
        # If set `true`, you may provide [amount](https://stripe.com/docs/api/issuing/authorizations/approve#approve_issuing_authorization-amount) to control how much to hold for the authorization.
        attr_accessor :is_amount_controllable

        def initialize(expand: nil, increment_amount: nil, is_amount_controllable: nil)
          @expand = expand
          @increment_amount = increment_amount
          @is_amount_controllable = is_amount_controllable
        end
      end
    end
  end
end
