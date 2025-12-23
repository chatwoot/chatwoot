# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Billing
      class MeterEventSession < APIResource
        OBJECT_NAME = "v2.billing.meter_event_session"
        def self.object_name
          "v2.billing.meter_event_session"
        end

        # The authentication token for this session.  Use this token when calling the
        # high-throughput meter event API.
        attr_reader :authentication_token
        # The creation time of this session.
        attr_reader :created
        # The time at which this session will expire.
        attr_reader :expires_at
        # The unique id of this auth session.
        attr_reader :id
        # String representing the object's type. Objects of the same type share the same value of the object field.
        attr_reader :object
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
