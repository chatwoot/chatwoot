# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A discount represents the actual application of a [coupon](https://stripe.com/docs/api#coupons) or [promotion code](https://stripe.com/docs/api#promotion_codes).
  # It contains information about when the discount began, when it will end, and what it is applied to.
  #
  # Related guide: [Applying discounts to subscriptions](https://stripe.com/docs/billing/subscriptions/discounts)
  class Discount < StripeObject
    OBJECT_NAME = "discount"
    def self.object_name
      "discount"
    end

    class Source < ::Stripe::StripeObject
      # The coupon that was redeemed to create this discount.
      attr_reader :coupon
      # The source type of the discount.
      attr_reader :type

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # The Checkout session that this coupon is applied to, if it is applied to a particular session in payment mode. Will not be present for subscription mode.
    attr_reader :checkout_session
    # The ID of the customer associated with this discount.
    attr_reader :customer
    # If the coupon has a duration of `repeating`, the date that this discount will end. If the coupon has a duration of `once` or `forever`, this attribute will be null.
    attr_reader :end
    # The ID of the discount object. Discounts cannot be fetched by ID. Use `expand[]=discounts` in API calls to expand discount IDs in an array.
    attr_reader :id
    # The invoice that the discount's coupon was applied to, if it was applied directly to a particular invoice.
    attr_reader :invoice
    # The invoice item `id` (or invoice line item `id` for invoice line items of type='subscription') that the discount's coupon was applied to, if it was applied directly to a particular invoice item or invoice line item.
    attr_reader :invoice_item
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The promotion code applied to create this discount.
    attr_reader :promotion_code
    # Attribute for field source
    attr_reader :source
    # Date that the coupon was applied.
    attr_reader :start
    # The subscription that this coupon is applied to, if it is applied to a particular subscription.
    attr_reader :subscription
    # The subscription item that this coupon is applied to, if it is applied to a particular subscription item.
    attr_reader :subscription_item
    # Always true for a deleted object
    attr_reader :deleted

    def self.inner_class_types
      @inner_class_types = { source: Source }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
