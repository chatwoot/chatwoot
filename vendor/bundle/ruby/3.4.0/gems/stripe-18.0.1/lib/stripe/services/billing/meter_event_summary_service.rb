# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterEventSummaryService < StripeService
      # Retrieve a list of billing meter event summaries.
      def list(id, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/billing/meters/%<id>s/event_summaries", { id: CGI.escape(id) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
