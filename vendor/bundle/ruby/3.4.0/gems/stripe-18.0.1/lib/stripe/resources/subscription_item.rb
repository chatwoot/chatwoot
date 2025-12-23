# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Subscription items allow you to create customer subscriptions with more than
  # one plan, making it easy to represent complex billing relationships.
  class SubscriptionItem < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "subscription_item"
    def self.object_name
      "subscription_item"
    end

    class BillingThresholds < ::Stripe::StripeObject
      # Usage threshold that triggers the subscription to create an invoice
      attr_reader :usage_gte

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
    # Define thresholds at which an invoice will be sent, and the related subscription advanced to a new billing period
    attr_reader :billing_thresholds
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The end time of this subscription item's current billing period.
    attr_reader :current_period_end
    # The start time of this subscription item's current billing period.
    attr_reader :current_period_start
    # The discounts applied to the subscription item. Subscription item discounts are applied before subscription discounts. Use `expand[]=discounts` to expand each discount.
    attr_reader :discounts
    # Unique identifier for the object.
    attr_reader :id
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # You can now model subscriptions more flexibly using the [Prices API](https://stripe.com/docs/api#prices). It replaces the Plans API and is backwards compatible to simplify your migration.
    #
    # Plans define the base price, currency, and billing cycle for recurring purchases of products.
    # [Products](https://stripe.com/docs/api#products) help you track inventory or provisioning, and plans help you track pricing. Different physical goods or levels of service should be represented by products, and pricing options should be represented by plans. This approach lets you change prices without having to change your provisioning scheme.
    #
    # For example, you might have a single "gold" product that has plans for $10/month, $100/year, €9/month, and €90/year.
    #
    # Related guides: [Set up a subscription](https://stripe.com/docs/billing/subscriptions/set-up-subscription) and more about [products and prices](https://stripe.com/docs/products-prices/overview).
    attr_reader :plan
    # Prices define the unit cost, currency, and (optional) billing cycle for both recurring and one-time purchases of products.
    # [Products](https://stripe.com/docs/api#products) help you track inventory or provisioning, and prices help you track payment terms. Different physical goods or levels of service should be represented by products, and pricing options should be represented by prices. This approach lets you change prices without having to change your provisioning scheme.
    #
    # For example, you might have a single "gold" product that has prices for $10/month, $100/year, and €9 once.
    #
    # Related guides: [Set up a subscription](https://stripe.com/docs/billing/subscriptions/set-up-subscription), [create an invoice](https://stripe.com/docs/billing/invoices/create), and more about [products and prices](https://stripe.com/docs/products-prices/overview).
    attr_reader :price
    # The [quantity](https://stripe.com/docs/subscriptions/quantities) of the plan to which the customer should be subscribed.
    attr_reader :quantity
    # The `subscription` this `subscription_item` belongs to.
    attr_reader :subscription
    # The tax rates which apply to this `subscription_item`. When set, the `default_tax_rates` on the subscription do not apply to this `subscription_item`.
    attr_reader :tax_rates
    # Always true for a deleted object
    attr_reader :deleted

    # Adds a new item to an existing subscription. No existing items will be changed or replaced.
    def self.create(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: "/v1/subscription_items",
        params: params,
        opts: opts
      )
    end

    # Deletes an item from the subscription. Removing a subscription item from a subscription will not cancel the subscription.
    def self.delete(item, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/subscription_items/%<item>s", { item: CGI.escape(item) }),
        params: params,
        opts: opts
      )
    end

    # Deletes an item from the subscription. Removing a subscription item from a subscription will not cancel the subscription.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/subscription_items/%<item>s", { item: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your subscription items for a given subscription.
    def self.list(params = {}, opts = {})
      request_stripe_object(
        method: :get,
        path: "/v1/subscription_items",
        params: params,
        opts: opts
      )
    end

    # Updates the plan or quantity of an item on a current subscription.
    def self.update(item, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/subscription_items/%<item>s", { item: CGI.escape(item) }),
        params: params,
        opts: opts
      )
    end

    def self.inner_class_types
      @inner_class_types = { billing_thresholds: BillingThresholds }
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
