# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionItemUpdateParams < ::Stripe::RequestParams
    class BillingThresholds < ::Stripe::RequestParams
      # Number of units that meets the billing threshold to advance the subscription to a new billing period (e.g., it takes 10 $5 units to meet a $50 [monetary threshold](https://stripe.com/docs/api/subscriptions/update#update_subscription-billing_thresholds-amount_gte))
      attr_accessor :usage_gte

      def initialize(usage_gte: nil)
        @usage_gte = usage_gte
      end
    end

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

    class PriceData < ::Stripe::RequestParams
      class Recurring < ::Stripe::RequestParams
        # Specifies billing frequency. Either `day`, `week`, `month` or `year`.
        attr_accessor :interval
        # The number of intervals between subscription billings. For example, `interval=month` and `interval_count=3` bills every 3 months. Maximum of three years interval allowed (3 years, 36 months, or 156 weeks).
        attr_accessor :interval_count

        def initialize(interval: nil, interval_count: nil)
          @interval = interval
          @interval_count = interval_count
        end
      end
      # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
      attr_accessor :currency
      # The ID of the [Product](https://docs.stripe.com/api/products) that this [Price](https://docs.stripe.com/api/prices) will belong to.
      attr_accessor :product
      # The recurring components of a price such as `interval` and `interval_count`.
      attr_accessor :recurring
      # Only required if a [default tax behavior](https://stripe.com/docs/tax/products-prices-tax-categories-tax-behavior#setting-a-default-tax-behavior-(recommended)) was not provided in the Stripe Tax settings. Specifies whether the price is considered inclusive of taxes or exclusive of taxes. One of `inclusive`, `exclusive`, or `unspecified`. Once specified as either `inclusive` or `exclusive`, it cannot be changed.
      attr_accessor :tax_behavior
      # A positive integer in cents (or local equivalent) (or 0 for a free price) representing how much to charge.
      attr_accessor :unit_amount
      # Same as `unit_amount`, but accepts a decimal value in cents (or local equivalent) with at most 12 decimal places. Only one of `unit_amount` and `unit_amount_decimal` can be set.
      attr_accessor :unit_amount_decimal

      def initialize(
        currency: nil,
        product: nil,
        recurring: nil,
        tax_behavior: nil,
        unit_amount: nil,
        unit_amount_decimal: nil
      )
        @currency = currency
        @product = product
        @recurring = recurring
        @tax_behavior = tax_behavior
        @unit_amount = unit_amount
        @unit_amount_decimal = unit_amount_decimal
      end
    end
    # Define thresholds at which an invoice will be sent, and the subscription advanced to a new billing period. Pass an empty string to remove previously-defined thresholds.
    attr_accessor :billing_thresholds
    # The coupons to redeem into discounts for the subscription item.
    attr_accessor :discounts
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Indicates if a customer is on or off-session while an invoice payment is attempted. Defaults to `false` (on-session).
    attr_accessor :off_session
    # Use `allow_incomplete` to transition the subscription to `status=past_due` if a payment is required but cannot be paid. This allows you to manage scenarios where additional user actions are needed to pay a subscription's invoice. For example, SCA regulation may require 3DS authentication to complete payment. See the [SCA Migration Guide](https://stripe.com/docs/billing/migration/strong-customer-authentication) for Billing to learn more. This is the default behavior.
    #
    # Use `default_incomplete` to transition the subscription to `status=past_due` when payment is required and await explicit confirmation of the invoice's payment intent. This allows simpler management of scenarios where additional user actions are needed to pay a subscription’s invoice. Such as failed payments, [SCA regulation](https://stripe.com/docs/billing/migration/strong-customer-authentication), or collecting a mandate for a bank debit payment method.
    #
    # Use `pending_if_incomplete` to update the subscription using [pending updates](https://stripe.com/docs/billing/subscriptions/pending-updates). When you use `pending_if_incomplete` you can only pass the parameters [supported by pending updates](https://stripe.com/docs/billing/pending-updates-reference#supported-attributes).
    #
    # Use `error_if_incomplete` if you want Stripe to return an HTTP 402 status code if a subscription's invoice cannot be paid. For example, if a payment method requires 3DS authentication due to SCA regulation and further user action is needed, this parameter does not update the subscription and returns an error instead. This was the default behavior for API versions prior to 2019-03-14. See the [changelog](https://docs.stripe.com/changelog/2019-03-14) to learn more.
    attr_accessor :payment_behavior
    # The identifier of the new plan for this subscription item.
    attr_accessor :plan
    # The ID of the price object. One of `price` or `price_data` is required. When changing a subscription item's price, `quantity` is set to 1 unless a `quantity` parameter is provided.
    attr_accessor :price
    # Data used to generate a new [Price](https://stripe.com/docs/api/prices) object inline. One of `price` or `price_data` is required.
    attr_accessor :price_data
    # Determines how to handle [prorations](https://stripe.com/docs/billing/subscriptions/prorations) when the billing cycle changes (e.g., when switching plans, resetting `billing_cycle_anchor=now`, or starting a trial), or if an item's `quantity` changes. The default value is `create_prorations`.
    attr_accessor :proration_behavior
    # If set, the proration will be calculated as though the subscription was updated at the given time. This can be used to apply the same proration that was previewed with the [upcoming invoice](https://stripe.com/docs/api#retrieve_customer_invoice) endpoint.
    attr_accessor :proration_date
    # The quantity you'd like to apply to the subscription item you're creating.
    attr_accessor :quantity
    # A list of [Tax Rate](https://stripe.com/docs/api/tax_rates) ids. These Tax Rates will override the [`default_tax_rates`](https://stripe.com/docs/api/subscriptions/create#create_subscription-default_tax_rates) on the Subscription. When updating, pass an empty string to remove previously-defined tax rates.
    attr_accessor :tax_rates

    def initialize(
      billing_thresholds: nil,
      discounts: nil,
      expand: nil,
      metadata: nil,
      off_session: nil,
      payment_behavior: nil,
      plan: nil,
      price: nil,
      price_data: nil,
      proration_behavior: nil,
      proration_date: nil,
      quantity: nil,
      tax_rates: nil
    )
      @billing_thresholds = billing_thresholds
      @discounts = discounts
      @expand = expand
      @metadata = metadata
      @off_session = off_session
      @payment_behavior = payment_behavior
      @plan = plan
      @price = price
      @price_data = price_data
      @proration_behavior = proration_behavior
      @proration_date = proration_date
      @quantity = quantity
      @tax_rates = tax_rates
    end
  end
end
