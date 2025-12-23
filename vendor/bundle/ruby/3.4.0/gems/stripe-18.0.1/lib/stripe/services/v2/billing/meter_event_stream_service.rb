# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Billing
      class MeterEventStreamService < StripeService
        # Creates meter events. Events are processed asynchronously, including validation. Requires a meter event session for authentication. Supports up to 10,000 requests per second in livemode. For even higher rate-limits, contact sales.
        #
        # ** raises TemporarySessionExpiredError
        def create(params = {}, opts = {})
          request(
            method: :post,
            path: "/v2/billing/meter_event_stream",
            params: params,
            opts: opts,
            base_address: :meter_events
          )
        end
      end
    end
  end
end
