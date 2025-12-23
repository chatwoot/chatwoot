# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    # A feature represents a monetizable ability or functionality in your system.
    # Features can be assigned to products, and when those products are purchased, Stripe will create an entitlement to the feature for the purchasing customer.
    class Feature < APIResource
      extend Stripe::APIOperations::Create
      extend Stripe::APIOperations::List
      include Stripe::APIOperations::Save

      OBJECT_NAME = "entitlements.feature"
      def self.object_name
        "entitlements.feature"
      end

      # Inactive features cannot be attached to new products and will not be returned from the features list endpoint.
      attr_reader :active
      # Unique identifier for the object.
      attr_reader :id
      # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
      attr_reader :livemode
      # A unique key you provide as your own system identifier. This may be up to 80 characters.
      attr_reader :lookup_key
      # Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_reader :metadata
      # The feature's name, for your own purpose, not meant to be displayable to the customer.
      attr_reader :name
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object

      # Creates a feature
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/entitlements/features",
          params: params,
          opts: opts
        )
      end

      # Retrieve a list of features
      def self.list(params = {}, opts = {})
        request_stripe_object(
          method: :get,
          path: "/v1/entitlements/features",
          params: params,
          opts: opts
        )
      end

      # Update a feature's metadata or permanently deactivate it.
      def self.update(id, params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: format("/v1/entitlements/features/%<id>s", { id: CGI.escape(id) }),
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
