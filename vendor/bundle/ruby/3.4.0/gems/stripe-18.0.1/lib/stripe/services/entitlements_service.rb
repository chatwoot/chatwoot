# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class EntitlementsService < StripeService
    attr_reader :active_entitlements, :features

    def initialize(requestor)
      super
      @active_entitlements = Stripe::Entitlements::ActiveEntitlementService.new(@requestor)
      @features = Stripe::Entitlements::FeatureService.new(@requestor)
    end
  end
end
