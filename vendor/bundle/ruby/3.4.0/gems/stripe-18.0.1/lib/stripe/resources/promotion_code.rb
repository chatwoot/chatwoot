# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A Promotion Code represents a customer-redeemable code for an underlying promotion.
  # You can create multiple codes for a single promotion.
  #
  # If you enable promotion codes in your [customer portal configuration](https://stripe.com/docs/customer-management/configure-portal), then customers can redeem a code themselves when updating a subscription in the portal.
  # Customers can also view the currently active promotion codes and coupons on each of their subscriptions in the portal.
  class PromotionCode < APIResource
    extend Stripe::APIOperations::Create
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "promotion_code"
    def self.object_name
      "promotion_code"
    end

    class Promotion < ::Stripe::StripeObject
      # If promotion `type` is `coupon`, the coupon for this promotion.
      attr_reader :coupon
      # The type of promotion.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class Restrictions < ::Stripe::StripeObject
      class CurrencyOptions < ::Stripe::StripeObject
        # Minimum amount required to redeem this Promotion Code into a Coupon (e.g., a purchase must be $100 or more to work).
        attr_reader :minimum_amount

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
      # Promotion code restrictions defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
      attr_reader :currency_options
      # A Boolean indicating if the Promotion Code should only be redeemed for Customers without any successful payments or invoices
      attr_reader :first_time_transaction
      # Minimum amount required to redeem this Promotion Code into a Coupon (e.g., a purchase must be $100 or more to work).
      attr_reader :minimum_amount
      # Three-letter [ISO code](https://stripe.com/docs/currencies) for minimum_amount
      attr_reader :minimum_amount_currency

      def self.inner_class_types
        @inner_class_types = { currency_options: CurrencyOptions }
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Whether the promotion code is currently active. A promotion code is only active if the coupon is also valid.
    attr_reader :active
    # The customer-facing code. Regardless of case, this code must be unique across all active promotion codes for each customer. Valid characters are lower case letters (a-z), upper case letters (A-Z), and digits (0-9).
    attr_reader :code
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The customer that this promotion code can be used by.
    attr_reader :customer
    # Date at which the promotion code can no longer be redeemed.
    attr_reader :expires_at
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Maximum number of times this promotion code can be redeemed.
    attr_reader :max_redemptions
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Attribute for field promotion
    attr_reader :promotion
    # Attribute for field restrictions
    attr_reader :restrictions
    # Number of times this promotion code has been used.
    attr_reader :times_redeemed

    # A promotion code points to an underlying promotion. You can optionally restrict the code to a specific customer, redemption limit, and expiration date.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/promotion_codes", params: params, opts: opts)
    end

    # Returns a list of your promotion codes.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/promotion_codes", params: params, opts: opts)
    end

    # Updates the specified promotion code by setting the values of the parameters passed. Most fields are, by design, not editable.
    def self.update(promotion_code, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/promotion_codes/%<promotion_code>s", { promotion_code: CGI.escape(promotion_code) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = { promotion: Promotion, restrictions: Restrictions }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
