# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PriceUpdateParams < ::Stripe::RequestParams
    class CurrencyOptions < ::Stripe::RequestParams
      class CustomUnitAmount < ::Stripe::RequestParams
        # Pass in `true` to enable `custom_unit_amount`, otherwise omit `custom_unit_amount`.
        attr_accessor :enabled
        # The maximum unit amount the customer can specify for this item.
        attr_accessor :maximum
        # The minimum unit amount the customer can specify for this item. Must be at least the minimum charge amount.
        attr_accessor :minimum
        # The starting unit amount which can be updated by the customer.
        attr_accessor :preset

        def initialize(enabled: nil, maximum: nil, minimum: nil, preset: nil)
          @enabled = enabled
          @maximum = maximum
          @minimum = minimum
          @preset = preset
        end
      end

      class Tier < ::Stripe::RequestParams
        # The flat billing amount for an entire tier, regardless of the number of units in the tier.
        attr_accessor :flat_amount
        # Same as `flat_amount`, but accepts a decimal value representing an integer in the minor units of the currency. Only one of `flat_amount` and `flat_amount_decimal` can be set.
        attr_accessor :flat_amount_decimal
        # The per unit billing amount for each individual unit for which this tier applies.
        attr_accessor :unit_amount
        # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
        attr_accessor :unit_amount_decimal
        # Specifies the upper bound of this tier. The lower bound of a tier is the upper bound of the previous tier adding one. Use `inf` to define a fallback tier.
        attr_accessor :up_to

        def initialize(
          flat_amount: nil,
          flat_amount_decimal: nil,
          unit_amount: nil,
          unit_amount_decimal: nil,
          up_to: nil
        )
          @flat_amount = flat_amount
          @flat_amount_decimal = flat_amount_decimal
          @unit_amount = unit_amount
          @unit_amount_decimal = unit_amount_decimal
          @up_to = up_to
        end
      end
      # When set, provides configuration for the amount to be adjusted by the customer during Checkout Sessions and Payment Links.
      attr_accessor :custom_unit_amount
      # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
      attr_accessor :tax_behavior
      # Each element represents a pricing tier. This parameter requires `billing_scheme` to be set to `tiered`. See also the documentation for `billing_scheme`.
      attr_accessor :tiers
      # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        custom_unit_amount: nil,
        tax_behavior: nil,
        tiers: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @custom_unit_amount = custom_unit_amount
        @tax_behavior = tax_behavior
        @tiers = tiers
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
      end
    end
    # Whether the price can be used for new purchases. Defaults to `true`.
    attr_accessor :active
    # Prices defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency_options
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A lookup key used to retrieve prices dynamically from a static string. This may be up to 200 characters.
    attr_accessor :lookup_key
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # A brief description of the price, hidden from customers.
    attr_accessor :nickname
    # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
    attr_accessor :tax_behavior
    # If set to true, will atomically remove the lookup key from the existing price, and assign it to this price.
    attr_accessor :transfer_lookup_key

    def initialize(
      active: nil,
      currency_options: nil,
      expand: nil,
      lookup_key: nil,
      metadata: nil,
      nickname: nil,
      tax_behavior: nil,
      transfer_lookup_key: nil
    )
      @active = active
      @currency_options = currency_options
      @expand = expand
      @lookup_key = lookup_key
      @metadata = metadata
      @nickname = nickname
      @tax_behavior = tax_behavior
      @transfer_lookup_key = transfer_lookup_key
    end
  end
end
