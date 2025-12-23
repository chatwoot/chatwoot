# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class AlertTriggered < APIResource
      OBJECT_NAME = "billing.alert_triggered"
      def self.object_name
        "billing.alert_triggered"
      end

      # A billing alert is a resource that notifies you when a certain usage threshold on a meter is crossed. For example, you might create a billing alert to notify you when a certain user made 100 API requests.
      attr_reader :alert
      # Time at which the object was created. Measured in seconds since the Unix epoch.
      attr_reader :created
      # ID of customer for which the alert triggered
      attr_reader :customer
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # The value triggering the alert
      attr_reader :value

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
