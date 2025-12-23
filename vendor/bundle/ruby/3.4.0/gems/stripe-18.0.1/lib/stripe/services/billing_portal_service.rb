# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class BillingPortalService < StripeService
    attr_reader :configurations, :sessions

    def initialize(requestor)
      super
      @configurations = Stripe::BillingPortal::ConfigurationService.new(@requestor)
      @sessions = Stripe::BillingPortal::SessionService.new(@requestor)
    end
  end
end
