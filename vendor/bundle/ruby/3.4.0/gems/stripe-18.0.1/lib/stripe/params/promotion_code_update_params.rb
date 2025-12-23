# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PromotionCodeUpdateParams < ::Stripe::RequestParams
    class Restrictions < ::Stripe::RequestParams
      class CurrencyOptions < ::Stripe::RequestParams
        # Minimum amount required to redeem this Promotion Code into a Coupon (e.g., a purchase must be $100 or more to work).
        attr_accessor :minimum_amount

        def initialize(minimum_amount: nil)
          @minimum_amount = minimum_amount
        end
      end
      # Promotion codes defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency_options

      def initialize(currency_options: nil)
        @currency_options = currency_options
      end
    end
    # Whether the promotion code is currently active. A promotion code can only be reactivated when the coupon is still valid and the promotion code is otherwise redeemable.
    attr_accessor :active
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Settings that restrict the redemption of the promotion code.
    attr_accessor :restrictions

    def initialize(active: nil, expand: nil, metadata: nil, restrictions: nil)
      @active = active
      @expand = expand
      @metadata = metadata
      @restrictions = restrictions
    end
  end
end
