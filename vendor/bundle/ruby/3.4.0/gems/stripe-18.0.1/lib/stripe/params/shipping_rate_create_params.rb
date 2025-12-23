# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ShippingRateCreateParams < ::Stripe::RequestParams
    class DeliveryEstimate < ::Stripe::RequestParams
      class Maximum < ::Stripe::RequestParams
        # A unit of time.
        attr_accessor :unit
        # Must be greater than 0.
        attr_accessor :value

        def initialize(unit: nil, value: nil)
          @unit = unit
          @value = value
        end
      end

      class Minimum < ::Stripe::RequestParams
        # A unit of time.
        attr_accessor :unit
        # Must be greater than 0.
        attr_accessor :value

        def initialize(unit: nil, value: nil)
          @unit = unit
          @value = value
        end
      end
      # The upper bound of the estimated range. If empty, represents no upper bound i.e., infinite.
      attr_accessor :maximum
      # The lower bound of the estimated range. If empty, represents no lower bound.
      attr_accessor :minimum

      def initialize(maximum: nil, minimum: nil)
        @maximum = maximum
        @minimum = minimum
      end
    end

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
      # A non-negative integer in cents representing how much to charge.
      attr_accessor :amount
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # Shipping rates defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency_options

      def initialize(amount: nil, currency: nil, currency_options: nil)
        @amount = amount
        @currency = currency
        @currency_options = currency_options
      end
    end
    # The estimated range for how long shipping will take, meant to be displayable to the customer. This will appear on CheckoutSessions.
    attr_accessor :delivery_estimate
    # The name of the shipping rate, meant to be displayable to the customer. This will appear on CheckoutSessions.
    attr_accessor :display_name
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Describes a fixed amount to charge for shipping. Must be present if type is `fixed_amount`.
    attr_accessor :fixed_amount
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Specifies whether the rate is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`.
    attr_accessor :tax_behavior
    # A [tax code](https://stripe.com/docs/tax/tax-categories) ID. The Shipping tax code is `txcd_92010001`.
    attr_accessor :tax_code
    # The type of calculation to use on the shipping rate.
    attr_accessor :type

    def initialize(
      delivery_estimate: nil,
      display_name: nil,
      expand: nil,
      fixed_amount: nil,
      metadata: nil,
      tax_behavior: nil,
      tax_code: nil,
      type: nil
    )
      @delivery_estimate = delivery_estimate
      @display_name = display_name
      @expand = expand
      @fixed_amount = fixed_amount
      @metadata = metadata
      @tax_behavior = tax_behavior
      @tax_code = tax_code
      @type = type
    end
  end
end
