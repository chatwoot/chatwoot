# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterEventSummaryListParams < ::Stripe::RequestParams
      # The customer for which to fetch event summaries.
      attr_accessor :customer
      # The timestamp from when to stop aggregating meter events (exclusive). Must be aligned with minute boundaries.
      attr_accessor :end_time
      # A cursor for use in pagination. `ending_before` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, starting with `obj_bar`, your subsequent call can include `ending_before=obj_bar` in order to fetch the previous page of the list.
      attr_accessor :ending_before
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A limit on the number of objects to be returned. Limit can range between 1 and 100, and the default is 10.
      attr_accessor :limit
      # The timestamp from when to start aggregating meter events (inclusive). Must be aligned with minute boundaries.
      attr_accessor :start_time
      # A cursor for use in pagination. `starting_after` is an object ID that defines your place in the list. For instance, if you make a list request and receive 100 objects, ending with `obj_foo`, your subsequent call can include `starting_after=obj_foo` in order to fetch the next page of the list.
      attr_accessor :starting_after
      # Specifies what granularity to use when generating event summaries. If not specified, a single event summary would be returned for the specified time range. For hourly granularity, start and end times must align with hour boundaries (e.g., 00:00, 01:00, ..., 23:00). For daily granularity, start and end times must align with UTC day boundaries (00:00 UTC).
      attr_accessor :value_grouping_window

      def initialize(
        customer: nil,
        end_time: nil,
        ending_before: nil,
        expand: nil,
        limit: nil,
        start_time: nil,
        starting_after: nil,
        value_grouping_window: nil
      )
        @customer = customer
        @end_time = end_time
        @ending_before = ending_before
        @expand = expand
        @limit = limit
        @start_time = start_time
        @starting_after = starting_after
        @value_grouping_window = value_grouping_window
      end
    end
  end
end
