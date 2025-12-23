# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class InvoiceItemUpdateParams < ::Stripe::RequestParams
    class Discount < ::Stripe::RequestParams
      # ID of the coupon to create a new discount for.
      attr_accessor :coupon
      # ID of an existing discount on the object (or one of its ancestors) to reuse.
      attr_accessor :discount
      # ID of the promotion code to create a new discount for.
      attr_accessor :promotion_code

      def initialize(coupon: nil, discount: nil, promotion_code: nil)
        @coupon = coupon
        @discount = discount
        @promotion_code = promotion_code
      end
    end

    class Period < ::Stripe::RequestParams
      # The end of the period, which must be greater than or equal to the start. This value is inclusive.
      attr_accessor :end
      # The start of the period. This value is inclusive.
      attr_accessor :start

      def initialize(end_: nil, start: nil)
        @end = end_
        @start = start
      end
    end

    class PriceData < ::Stripe::RequestParams
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # The ID of the [Product](https://docs.stripe.com/api/products) that this [Price](https://docs.stripe.com/api/prices) will belong to.
      attr_accessor :product
      # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
      attr_accessor :tax_behavior
      # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        currency: nil,
        product: nil,
        tax_behavior: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @currency = currency
        @product = product
        @tax_behavior = tax_behavior
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
      end
    end

    class Pricing < ::Stripe::RequestParams
      # The ID of the price object.
      attr_accessor :price

      def initialize(price: nil)
        @price = price
      end
    end
    # The integer amount in cents (or local equivalent) of the charge to be applied to the upcoming invoice. If you want to apply a credit to the customer's account, pass a negative amount.
    attr_accessor :amount
    # An arbitrary string which you can attach to the invoice item. The description is displayed in the invoice for easy tracking.
    attr_accessor :description
    # Controls whether discounts apply to this invoice item. Defaults to false for prorations or negative invoice items, and true for all other invoice items. Cannot be set to true for prorations.
    attr_accessor :discountable
    # The coupons, promotion codes & existing discounts which apply to the invoice item or invoice line item. Item discounts are applied before invoice discounts. Pass an empty string to remove previously-defined discounts.
    attr_accessor :discounts
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The period associated with this invoice item. When set to different values, the period will be rendered on the invoice. If you have [Stripe Revenue Recognition](https://stripe.com/docs/revenue-recognition) enabled, the period will be used to recognize and defer revenue. See the [Revenue Recognition documentation](https://stripe.com/docs/revenue-recognition/methodology/subscriptions-and-invoicing) for details.
    attr_accessor :period
    # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline.
    attr_accessor :price_data
    # The pricing information for the invoice item.
    attr_accessor :pricing
    # Non-negative integer. The quantity of units for the invoice item.
    attr_accessor :quantity
    # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
    attr_accessor :tax_behavior
    # A [tax code](https://stripe.com/docs/tax/tax-categories) ID.
    attr_accessor :tax_code
    # The tax rates which apply to the invoice item. When set, the `default_tax_rates` on the invoice do not apply to this invoice item. Pass an empty string to remove previously-defined tax rates.
    attr_accessor :tax_rates
    # The decimal unit amount in cents (or local equivalent) of the charge to be applied to the upcoming invoice. This `unit_amount_decimal` will be multiplied by the quantity to get the full amount. Passing in a negative `unit_amount_decimal` will reduce the `amount_due` on the invoice. Accepts at most 12 decimal places.
    attr_accessor :unit_amount_decimal

    def initialize(
      amount: nil,
      description: nil,
      discountable: nil,
      discounts: nil,
      expand: nil,
      metadata: nil,
      period: nil,
      price_data: nil,
      pricing: nil,
      quantity: nil,
      tax_behavior: nil,
      tax_code: nil,
      tax_rates: nil,
      unit_amount_decimal: nil
    )
      @amount = amount
      @description = description
      @discountable = discountable
      @discounts = discounts
      @expand = expand
      @metadata = metadata
      @period = period
      @price_data = price_data
      @pricing = pricing
      @quantity = quantity
      @tax_behavior = tax_behavior
      @tax_code = tax_code
      @tax_rates = tax_rates
      @unit_amount_decimal = unit_amount_decimal
    end
  end
end
