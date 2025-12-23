# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A coupon contains information about a percent-off or amount-off discount you
  # might want to apply to a customer. Coupons may be applied to [subscriptions](https://stripe.com/docs/api#subscriptions), [invoices](https://stripe.com/docs/api#invoices),
  # [checkout sessions](https://stripe.com/docs/api/checkout/sessions), [quotes](https://stripe.com/docs/api#quotes), and more. Coupons do not work with conventional one-off [charges](https://stripe.com/docs/api#create_charge) or [payment intents](https://stripe.com/docs/api/payment_intents).
  class Coupon < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "coupon"
    def self.object_name
      "coupon"
    end

    class AppliesTo < ::Stripe::StripeObject
      # A list of product IDs this coupon applies to
      attr_reader :products

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end

    class CurrencyOptions < ::Stripe::StripeObject
      # Amount (in the `currency` specified) that will be taken off the subtotal of any invoices for this customer.
      attr_reader :amount_off

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Amount (in the `currency` specified) that will be taken off the subtotal of any invoices for this customer.
    attr_reader :amount_off
    # Attribute for field applies_to
    attr_reader :applies_to
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # If `amount_off` has been set, the three-letter [ISO code for the currency](https://stripe.com/docs/currencies) of the amount to take off.
    attr_reader :currency
    # Coupons defined in each available currency option. Each key must be a three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) and a [supported currency](https://stripe.com/docs/currencies).
    attr_reader :currency_options
    # One of `forever`, `once`, or `repeating`. Describes how long a customer who applies this coupon will get the discount.
    attr_reader :duration
    # If `duration` is `repeating`, the number of months the coupon applies. Null if coupon `duration` is `forever` or `once`.
    attr_reader :duration_in_months
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Maximum number of times this coupon can be redeemed, in total, across all customers, before it is no longer valid.
    attr_reader :max_redemptions
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # Name of the coupon displayed to customers on for instance invoices or receipts.
    attr_reader :name
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Percent that will be taken off the subtotal of any invoices for this customer for the duration of the coupon. For example, a coupon with percent_off of 50 will make a $ (or local equivalent)100 invoice $ (or local equivalent)50 instead.
    attr_reader :percent_off
    # Date after which the coupon can no longer be redeemed.
    attr_reader :redeem_by
    # Number of times this coupon has been applied to a customer.
    attr_reader :times_redeemed
    # Taking account of the above properties, whether this coupon can still be applied to a customer.
    attr_reader :valid
    # Always true for a deleted object
    attr_reader :deleted

    # You can create coupons easily via the [coupon management](https://dashboard.stripe.com/coupons) page of the Stripe dashboard. Coupon creation is also accessible via the API if you need to create coupons on the fly.
    #
    # A coupon has either a percent_off or an amount_off and currency. If you set an amount_off, that amount will be subtracted from any invoice's subtotal. For example, an invoice with a subtotal of 100 will have a final total of 0 if a coupon with an amount_off of 200 is applied to it and an invoice with a subtotal of 300 will have a final total of 100 if a coupon with an amount_off of 200 is applied to it.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/coupons", params: params, opts: opts)
    end

    # You can delete coupons via the [coupon management](https://dashboard.stripe.com/coupons) page of the Stripe dashboard. However, deleting a coupon does not affect any customers who have already applied the coupon; it means that new customers can't redeem the coupon. You can also delete coupons via the API.
    def self.delete(coupon, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/coupons/%<coupon>s", { coupon: CGI.escape(coupon) }),
        params: params,
        opts: opts
      )
    end

    # You can delete coupons via the [coupon management](https://dashboard.stripe.com/coupons) page of the Stripe dashboard. However, deleting a coupon does not affect any customers who have already applied the coupon; it means that new customers can't redeem the coupon. You can also delete coupons via the API.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/coupons/%<coupon>s", { coupon: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your coupons.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/coupons", params: params, opts: opts)
    end

    # Updates the metadata of a coupon. Other coupon details (currency, duration, amount_off) are, by design, not editable.
    def self.update(coupon, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/coupons/%<coupon>s", { coupon: CGI.escape(coupon) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = { applies_to: AppliesTo, currency_options: CurrencyOptions }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
