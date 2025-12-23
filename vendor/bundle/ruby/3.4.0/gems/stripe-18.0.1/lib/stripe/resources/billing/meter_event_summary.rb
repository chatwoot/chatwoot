# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    # A billing meter event summary represents an aggregated view of a customer's billing meter events within a specified timeframe. It indicates how much
    # usage was accrued by a customer for that period.
    #
    # Note: Meters events are aggregated asynchronously so the meter event summaries provide an eventually consistent view of the reported usage.
    class MeterEventSummary < APIResource
      OBJECT_NAME = "billing.meter_event_summary"
      def self.object_name
        "billing.meter_event_summary"
      end

      # Aggregated value of all the events within `start_time` (inclusive) and `end_time` (inclusive). The aggregation strategy is defined on meter via `default_aggregation`.
      attr_reader :aggregated_value
      # End timestamp for this event summary (exclusive). Must be aligned with minute boundaries.
      attr_reader :end_time
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # The meter associated with this event summary.
      attr_reader :meter
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Start timestamp for this event summary (inclusive). Must be aligned with minute boundaries.
      attr_reader :start_time

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
