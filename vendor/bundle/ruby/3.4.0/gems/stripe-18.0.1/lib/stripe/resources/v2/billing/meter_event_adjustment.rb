# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Billing
      class MeterEventAdjustment < APIResource
        OBJECT_NAME = "v2.billing.meter_event_adjustment"
        def self.object_name
          "v2.billing.meter_event_adjustment"
        end

        class Cancel < ::Stripe::StripeObject
          # Unique identifier for the event. You can only cancel events within 24 hours of Stripe receiving them.
          attr_reader :identifier

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Specifies which event to cancel.
        attr_reader :cancel
        # The time the adjustment was created.
        attr_reader :created
        # The name of the meter event. Corresponds with the `event_name` field on a meter.
        attr_reader :event_name
        # The unique id of this meter event adjustment.
        attr_reader :id
        # String representing the object's type. Objects of the same type share the same value of the object field.
        attr_reader :object
        # Open Enum. The meter event adjustment’s status.
        attr_reader :status
        # Open Enum. Specifies whether to cancel a single event or a range of events for a time period. Time period cancellation is not supported yet.
        attr_reader :type
        # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
        attr_reader :livemode

        def self.inner_class_types
          @inner_class_types = { cancel: Cancel }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
    end
  end
end
