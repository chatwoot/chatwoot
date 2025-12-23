# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CouponUpdateParams < ::Stripe::RequestParams
    class CurrencyOptions < ::Stripe::RequestParams
      # A positive integer representing the amount to subtract from an invoice total.
      attr_accessor :amount_off

      def initialize(amount_off: nil)
        @amount_off = amount_off
      end
    end
    # Coupons defined in each available currency option (only supported if the coupon is amount-based). Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency_options
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Name of the coupon displayed to customers on, for instance invoices, or receipts. By default the `id` is shown if `name` is not set.
    attr_accessor :name

    def initialize(currency_options: nil, expand: nil, metadata: nil, name: nil)
      @currency_options = currency_options
      @expand = expand
      @metadata = metadata
      @name = name
    end
  end
end
