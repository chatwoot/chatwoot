# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Identity
    class VerificationReportService < StripeService
      # List all verification reports.
      def list(params = {}, opts = {})
        request(
          method: :get,
          path: "/v1/identity/verification_reports",
          params: params,
          opts: opts,
          base_address: :api
        )
      end

      # Retrieves an existing VerificationReport
      def retrieve(report, params = {}, opts = {})
        request(
          method: :get,
          path: format("/v1/identity/verification_reports/%<report>s", { report: CGI.escape(report) }),
          params: params,
          opts: opts,
          base_address: :api
        )
      end
    end
  end
end
