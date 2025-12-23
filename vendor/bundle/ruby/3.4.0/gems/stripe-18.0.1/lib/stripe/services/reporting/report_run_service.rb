# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Reporting
    class ReportRunService < StripeService
      # Creates a new object and begin running the report. (Certain report types require a [live-mode API key](https://stripe.com/docs/keys#test-live-modes).)
      def create(params = {}, opts = {})
        request(
          method: :post,
          path: "/v1/reporting/report_runs",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Returns a list of Report Runs, with the most recent appearing first.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/reporting/report_runs",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves the details of an existing Report Run.
      def retrieve(report_run, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/reporting/report_runs/%<report_run>s", { report_run: CGI.escape(report_run) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
