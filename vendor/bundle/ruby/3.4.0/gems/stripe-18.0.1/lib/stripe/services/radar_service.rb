# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class RadarService < StripeService
    attr_reader :early_fraud_warnings, :value_lists, :value_list_items

    def initialize(requestor)
      super
      @early_fraud_warnings = Stripe::Radar::EarlyFraudWarningService.new(@requestor)
      @value_lists = Stripe::Radar::ValueListService.new(@requestor)
      @value_list_items = Stripe::Radar::ValueListItemService.new(@requestor)
    end
  end
end
