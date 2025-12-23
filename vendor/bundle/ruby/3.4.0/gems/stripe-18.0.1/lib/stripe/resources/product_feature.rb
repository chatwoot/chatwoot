# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # A product_feature represents an attachment between a feature and a product.
  # When a product is purchased that has a feature attached, Stripe will create an entitlement to the feature for the purchasing customer.
  class ProductFeature < APIResource
    OBJECT_NAME = "product_feature"
    def self.object_name
      "product_feature"
    end

    # A feature represents a monetizable ability or functionality in your system.
    # Features can be assigned to products, and when those products are purchased, Stripe will create an entitlement to the feature for the purchasing customer.
    attr_reader :entitlement_feature
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Always true for a deleted object
    attr_reader :deleted

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
