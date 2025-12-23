# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Billing
      # Fix me empty_doc_string.
      class MeterEvent < APIResource
        OBJECT_NAME = "v2.billing.meter_event"
        def self.object_name
          "v2.billing.meter_event"
        end

        # The creation time of this meter event.
        attr_reader :created
        # The name of the meter event. Corresponds with the `event_name` field on a meter.
        attr_reader :event_name
        # A unique identifier for the event. If not provided, one will be generated. We recommend using a globally unique identifier for this. We’ll enforce uniqueness within a rolling 24 hour period.
        attr_reader :identifier
        # String representing the object's type. Objects of the same type share the same value of the object field.
        attr_reader :object
        # The payload of the event. This must contain the fields corresponding to a meter’s
        # `customer_mapping.event_payload_key` (default is `stripe_customer_id`) and
        # `value_settings.event_payload_key` (default is `value`). Read more about
        # the [payload](https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage#payload-key-overrides)..
        attr_reader :payload
        # The time of the event. Must be within the past 35 calendar days or up to
        # 5 minutes in the future. Defaults to current timestamp if not specified.
        attr_reader :timestamp
        # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
        attr_reader :livemode

        def self.inner_class_types
          @inner_class_types = {}
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
    end
  end
end
