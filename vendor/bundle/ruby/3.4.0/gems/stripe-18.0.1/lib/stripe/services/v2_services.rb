# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class V2Services < StripeService
    attr_reader :billing, :core

    def initialize(requestor)
      super
      @billing = Stripe::V2::BillingService.new(@requestor)
      @core = Stripe::V2::CoreService.new(@requestor)
    end
  end
end
