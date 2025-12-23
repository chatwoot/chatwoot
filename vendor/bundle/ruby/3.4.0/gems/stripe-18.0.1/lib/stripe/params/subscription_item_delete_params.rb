# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionItemDeleteParams < ::Stripe::RequestParams
    # Delete all usage for the given subscription item. Allowed only when the current plan's `usage_type` is `metered`.
    attr_accessor :clear_usage
    # Determines how to handle [prorations](https://stripe.com/docs/billing/subscriptions/prorations) when the billing cycle changes (e.g., when switching plans, resetting `billing_cycle_anchor=now`, or starting a trial), or if an item's `quantity` changes. The default value is `create_prorations`.
    attr_accessor :proration_behavior
    # If set, the proration will be calculated as though the subscription was updated at the given time. This can be used to apply the same proration that was previewed with the [upcoming invoice](https://stripe.com/docs/api#retrieve_customer_invoice) endpoint.
    attr_accessor :proration_date

    def initialize(clear_usage: nil, proration_behavior: nil, proration_date: nil)
      @clear_usage = clear_usage
      @proration_behavior = proration_behavior
      @proration_date = proration_date
    end
  end
end
