# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SubscriptionScheduleReleaseParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Keep any cancellation on the subscription that the schedule has set
    attr_accessor :preserve_cancel_date

    def initialize(expand: nil, preserve_cancel_date: nil)
      @expand = expand
      @preserve_cancel_date = preserve_cancel_date
    end
  end
end
