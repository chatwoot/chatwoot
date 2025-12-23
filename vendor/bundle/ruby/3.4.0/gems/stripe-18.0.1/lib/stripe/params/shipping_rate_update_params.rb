# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ShippingRateUpdateParams < ::Stripe::RequestParams
    class FixedAmount < ::Stripe::RequestParams
      class CurrencyOptions < ::Stripe::RequestParams
        # A non-negative integer in cents representing how much to charge.
        attr_accessor :amount
        # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
        attr_accessor :tax_behavior

        def initialize(amount: nil, tax_behavior: nil)
          @amount = amount
          @tax_behavior = tax_behavior
        end
      end
      # Shipping rates defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency_options

      def initialize(currency_options: nil)
        @currency_options = currency_options
      end
    end
    # Whether the shipping rate can be used for new purchases. Defaults to `true`.
    attr_accessor :active
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Describes a fixed amount to charge for shipping. Must be present if type is `fixed_amount`.
    attr_accessor :fixed_amount
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
    attr_accessor :tax_behavior

    def initialize(active: nil, expand: nil, fixed_amount: nil, metadata: nil, tax_behavior: nil)
      @active = active
      @expand = expand
      @fixed_amount = fixed_amount
      @metadata = metadata
      @tax_behavior = tax_behavior
    end
  end
end
