# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    # Meter events represent actions that customers take in your system. You can use meter events to bill a customer based on their usage. Meter events are associated with billing meters, which define both the contents of the event's payload and how to aggregate those events.
    class MeterEvent < APIResource
      extend Stripe::APIOperations::Create

      OBJECT_NAME = "billing.meter_event"
      def self.object_name
        "billing.meter_event"
      end

      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # The name of the meter event. Corresponds with the `event_name` field on a meter.
      attr_reader :event_name
      # A unique identifier for the event.
      attr_reader :identifier
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The payload of the event. This contains the fields corresponding to a meter's `customer_mapping.event_payload_key` (default is `stripe_customer_id`) and `value_settings.event_payload_key` (default is `value`). Read more about the [payload](https://stripe.com/docs/billing/subscriptions/usage-based/recording-usage#payload-key-overrides).
      attr_reader :payload
      # The timestamp passed in when creating the event. Measured in seconds since the Unix epoch.
      attr_reader :timestamp

      # Creates a billing meter event.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/billing/meter_events",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
