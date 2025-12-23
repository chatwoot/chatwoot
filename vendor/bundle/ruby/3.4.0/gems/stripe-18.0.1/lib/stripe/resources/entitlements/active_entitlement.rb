# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    # An active entitlement describes access to a feature for a customer.
    class ActiveEntitlement < APIResource
      extend Stripe::APIOperations::List

      OBJECT_NAME = "entitlements.active_entitlement"
      def self.object_name
        "entitlements.active_entitlement"
      end

      # The [Feature](https://stripe.com/docs/api/entitlements/feature) that the customer is entitled to.
      attr_reader :feature
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # A unique key you provide as your own system identifier. This may be up to 80 characters.
      attr_reader :lookup_key
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object

      # Retrieve a list of active entitlements for a customer
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/entitlements/active_entitlements",
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
