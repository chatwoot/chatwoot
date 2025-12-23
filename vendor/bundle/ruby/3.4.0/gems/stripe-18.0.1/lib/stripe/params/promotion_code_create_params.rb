# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PromotionCodeCreateParams < ::Stripe::RequestParams
    class Promotion < ::Stripe::RequestParams
      # If promotion `type` is `coupon`, the coupon for this promotion code.
      attr_accessor :coupon
      # Specifies the type of promotion.
      attr_accessor :type

      def initialize(coupon: nil, type: nil)
        @coupon = coupon
        @type = type
      end
    end

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
      # A Boolean indicating if the Promotion Code should only be redeemed for Customers without any successful payments or invoices
      attr_accessor :first_time_transaction
      # Minimum amount required to redeem this Promotion Code into a Coupon (e.g., a purchase must be $100 or more to work).
      attr_accessor :minimum_amount
      # Three-letter [ISO code](https://stripe.com/docs/currencies) for minimum_amount
      attr_accessor :minimum_amount_currency

      def initialize(
        currency_options: nil,
        first_time_transaction: nil,
        minimum_amount: nil,
        minimum_amount_currency: nil
      )
        @currency_options = currency_options
        @first_time_transaction = first_time_transaction
        @minimum_amount = minimum_amount
        @minimum_amount_currency = minimum_amount_currency
      end
    end
    # Whether the promotion code is currently active.
    attr_accessor :active
    # The customer-facing code. Regardless of case, this code must be unique across all active promotion codes for a specific customer. Valid characters are lower case letters (a-z), upper case letters (A-Z), and digits (0-9).
    #
    # If left blank, we will generate one automatically.
    attr_accessor :code
    # The customer that this promotion code can be used by. If not set, the promotion code can be used by all customers.
    attr_accessor :customer
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The timestamp at which this promotion code will expire. If the coupon has specified a `redeems_by`, then this value cannot be after the coupon's `redeems_by`.
    attr_accessor :expires_at
    # A positive integer specifying the number of times the promotion code can be redeemed. If the coupon has specified a `max_redemptions`, then this value cannot be greater than the coupon's `max_redemptions`.
    attr_accessor :max_redemptions
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The promotion referenced by this promotion code.
    attr_accessor :promotion
    # Settings that restrict the redemption of the promotion code.
    attr_accessor :restrictions

    def initialize(
      active: nil,
      code: nil,
      customer: nil,
      expand: nil,
      expires_at: nil,
      max_redemptions: nil,
      metadata: nil,
      promotion: nil,
      restrictions: nil
    )
      @active = active
      @code = code
      @customer = customer
      @expand = expand
      @expires_at = expires_at
      @max_redemptions = max_redemptions
      @metadata = metadata
      @promotion = promotion
      @restrictions = restrictions
    end
  end
end
