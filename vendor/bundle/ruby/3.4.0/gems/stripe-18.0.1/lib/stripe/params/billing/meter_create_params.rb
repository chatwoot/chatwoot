# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterCreateParams < ::Stripe::RequestParams
      class CustomerMapping < ::Stripe::RequestParams
        # The key in the meter event payload to use for mapping the event to a customer.
        attr_accessor :event_payload_key
        # The method for mapping a meter event to a customer. Must be `by_id`.
        attr_accessor :type

        def initialize(event_payload_key: nil, type: nil)
          @event_payload_key = event_payload_key
          @type = type
        end
      end

      class DefaultAggregation < ::Stripe::RequestParams
        # Specifies how events are aggregated. Allowed values are `count` to count the number of events, `sum` to sum each event's value and `last` to take the last event's value in the window.
        attr_accessor :formula

        def initialize(formula: nil)
          @formula = formula
        end
      end

      class ValueSettings < ::Stripe::RequestParams
        # The key in the usage event payload to use as the value for this meter. For example, if the event payload contains usage on a `bytes_used` field, then set the event_payload_key to "bytes_used".
        attr_accessor :event_payload_key

        def initialize(event_payload_key: nil)
          @event_payload_key = event_payload_key
        end
      end
      # Fields that specify how to map a meter event to a customer.
      attr_accessor :customer_mapping
      # The default settings to aggregate a meter's events with.
      attr_accessor :default_aggregation
      # The meter’s name. Not visible to the customer.
      attr_accessor :display_name
      # The name of the meter event to record usage for. Corresponds with the `event_name` field on meter events.
      attr_accessor :event_name
      # The time window which meter events have been pre-aggregated for, if any.
      attr_accessor :event_time_window
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Fields that specify how to calculate a meter event's value.
      attr_accessor :value_settings

      def initialize(
        customer_mapping: nil,
        default_aggregation: nil,
        display_name: nil,
        event_name: nil,
        event_time_window: nil,
        expand: nil,
        value_settings: nil
      )
        @customer_mapping = customer_mapping
        @default_aggregation = default_aggregation
        @display_name = display_name
        @event_name = event_name
        @event_time_window = event_time_window
        @expand = expand
        @value_settings = value_settings
      end
    end
  end
end
