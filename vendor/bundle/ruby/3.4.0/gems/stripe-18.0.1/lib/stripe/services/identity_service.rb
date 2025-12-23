# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class IdentityService < StripeService
    attr_reader :verification_reports, :verification_sessions

    def initialize(requestor)
      super
      @verification_reports = Stripe::Identity::VerificationReportService.new(@requestor)
      @verification_sessions = Stripe::Identity::VerificationSessionService.new(@requestor)
    end
  end
end
