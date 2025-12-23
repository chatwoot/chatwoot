# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionResumeParams < ::Stripe::RequestParams
    # The billing cycle anchor that applies when the subscription is resumed. Either `now` or `unchanged`. The default is `now`. For more information, see the billing cycle [documentation](https://stripe.com/docs/billing/subscriptions/billing-cycle).
    attr_accessor :billing_cycle_anchor
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Determines how to handle [prorations](https://stripe.com/docs/billing/subscriptions/prorations) resulting from the `billing_cycle_anchor` being `unchanged`. When the `billing_cycle_anchor` is set to `now` (default value), no prorations are generated. If no value is passed, the default is `create_prorations`.
    attr_accessor :proration_behavior
    # If set, prorations will be calculated as though the subscription was resumed at the given time. This can be used to apply exactly the same prorations that were previewed with the [create preview](https://stripe.com/docs/api/invoices/create_preview) endpoint.
    attr_accessor :proration_date

    def initialize(
      billing_cycle_anchor: nil,
      expand: nil,
      proration_behavior: nil,
      proration_date: nil
    )
      @billing_cycle_anchor = billing_cycle_anchor
      @expand = expand
      @proration_behavior = proration_behavior
      @proration_date = proration_date
    end
  end
end
