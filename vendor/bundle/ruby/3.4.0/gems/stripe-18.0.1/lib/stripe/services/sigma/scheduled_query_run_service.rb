# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Sigma
    class ScheduledQueryRunService < StripeService
      # Returns a list of scheduled query runs.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/sigma/scheduled_query_runs",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an scheduled query run.
      def retrieve(scheduled_query_run, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/sigma/scheduled_query_runs/%<scheduled_query_run>s", { scheduled_query_run: CGI.escape(scheduled_query_run) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
