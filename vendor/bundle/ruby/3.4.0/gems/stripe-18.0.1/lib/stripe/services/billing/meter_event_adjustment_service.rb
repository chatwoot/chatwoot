# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterEventAdjustmentService < StripeService
      # Creates a billing meter event adjustment.
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/billing/meter_event_adjustments",
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
