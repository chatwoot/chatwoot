# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SigmaService < StripeService
    attr_reader :scheduled_query_runs

    def initialize(requestor)
      super
      @scheduled_query_runs = Stripe::Sigma::ScheduledQueryRunService.new(@requestor)
    end
  end
end
