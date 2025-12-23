# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterEventAdjustmentCreateParams < ::Stripe::RequestParams
      class Cancel < ::Stripe::RequestParams
        # Unique identifier for the event. You can only cancel events within 24 hours of Stripe receiving them.
        attr_accessor :identifier

        def initialize(identifier: nil)
          @identifier = identifier
        end
      end
      # Specifies which event to cancel.
      attr_accessor :cancel
      # The name of the meter event. Corresponds with the `event_name` field on a meter.
      attr_accessor :event_name
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Specifies whether to cancel a single event or a range of events for a time period. Time period cancellation is not supported yet.
      attr_accessor :type

      def initialize(cancel: nil, event_name: nil, expand: nil, type: nil)
        @cancel = cancel
        @event_name = event_name
        @expand = expand
        @type = type
      end
    end
  end
end
