# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CouponCreateParams < ::Stripe::RequestParams
    class AppliesTo < ::Stripe::RequestParams
      # An array of Product IDs that this Coupon will apply to.
      attr_accessor :products

      def initialize(products: nil)
        @products = products
      end
    end

    class CurrencyOptions < ::Stripe::RequestParams
      # A positive integer representing the amount to subtract from an invoice total.
      attr_accessor :amount_off

      def initialize(amount_off: nil)
        @amount_off = amount_off
      end
    end
    # A positive integer representing the amount to subtract from an invoice total (required if `percent_off` is not passed).
    attr_accessor :amount_off
    # A hash containing directions for what this Coupon will apply discounts to.
    attr_accessor :applies_to
    # Three-letter [ISO code for the currency](https://stripe.com/docs/currencies) of the `amount_off` parameter (required if `amount_off` is passed).
    attr_accessor :currency
    # Coupons defined in each available currency option (only supported if `amount_off` is passed). Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency_options
    # Specifies how long the discount will be in effect if used on a subscription. Defaults to `once`.
    attr_accessor :duration
    # Required only if `duration` is `repeating`, in which case it must be a positive integer that specifies the number of months the discount will be in effect.
    attr_accessor :duration_in_months
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Unique string of your choice that will be used to identify this coupon when applying it to a customer. If you don't want to specify a particular code, you can leave the ID blank and we'll generate a random code for you.
    attr_accessor :id
    # A positive integer specifying the number of times the coupon can be redeemed before it's no longer valid. For example, you might have a 50% off coupon that the first 20 readers of your blog can use.
    attr_accessor :max_redemptions
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Name of the coupon displayed to customers on, for instance invoices, or receipts. By default the `id` is shown if `name` is not set.
    attr_accessor :name
    # A positive float larger than 0, and smaller or equal to 100, that represents the discount the coupon will apply (required if `amount_off` is not passed).
    attr_accessor :percent_off
    # Unix timestamp specifying the last time at which the coupon can be redeemed. After the redeem_by date, the coupon can no longer be applied to new customers.
    attr_accessor :redeem_by

    def initialize(
      amount_off: nil,
      applies_to: nil,
      currency: nil,
      currency_options: nil,
      duration: nil,
      duration_in_months: nil,
      expand: nil,
      id: nil,
      max_redemptions: nil,
      metadata: nil,
      name: nil,
      percent_off: nil,
      redeem_by: nil
    )
      @amount_off = amount_off
      @applies_to = applies_to
      @currency = currency
      @currency_options = currency_options
      @duration = duration
      @duration_in_months = duration_in_months
      @expand = expand
      @id = id
      @max_redemptions = max_redemptions
      @metadata = metadata
      @name = name
      @percent_off = percent_off
      @redeem_by = redeem_by
    end
  end
end
