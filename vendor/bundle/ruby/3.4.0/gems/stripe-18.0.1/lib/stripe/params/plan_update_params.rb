# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PlanUpdateParams < ::Stripe::RequestParams
    # Whether the plan is currently available for new subscriptions.
    attr_accessor :active
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # A brief description of the plan, hidden from customers.
    attr_accessor :nickname
    # The product the plan belongs to. This cannot be changed once it has been used in a subscription or subscription schedule.
    attr_accessor :product
    # Default number of trial days when subscribing a customer to this plan using [`trial_from_plan=true`](https://stripe.com/docs/api#create_subscription-trial_from_plan).
    attr_accessor :trial_period_days

    def initialize(
      active: nil,
      expand: nil,
      metadata: nil,
      nickname: nil,
      product: nil,
      trial_period_days: nil
    )
      @active = active
      @expand = expand
      @metadata = metadata
      @nickname = nickname
      @product = product
      @trial_period_days = trial_period_days
    end
  end
end
