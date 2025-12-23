# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Billing
      class MeterEventAdjustmentService < StripeService
        # Creates a meter event adjustment to cancel a previously sent meter event.
        def create(params = {}, opts = {})
          request(
            method: :post,
            path: "/v2/billing/meter_event_adjustments",
            params: params,
            opts: opts,
            base_address: :api
          )
        end
      end
    end
  end
end
