# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    # A summary of a customer's active entitlements.
    class ActiveEntitlementSummary < APIResource
      OBJECT_NAME = "entitlements.active_entitlement_summary"
      def self.object_name
        "entitlements.active_entitlement_summary"
      end

      # The customer that is entitled to this feature.
      attr_reader :customer
      # The list of entitlements this customer has.
      attr_reader :entitlements
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
