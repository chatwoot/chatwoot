# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ReportingService < StripeService
    attr_reader :report_runs, :report_types

    def initialize(requestor)
      super
      @report_runs = Stripe::Reporting::ReportRunService.new(@requestor)
      @report_types = Stripe::Reporting::ReportTypeService.new(@requestor)
    end
  end
end
