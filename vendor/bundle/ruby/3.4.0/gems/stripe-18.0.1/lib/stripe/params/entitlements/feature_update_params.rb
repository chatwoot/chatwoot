# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    class FeatureUpdateParams < ::Stripe::RequestParams
      # Inactive features cannot be attached to new products and will not be returned from the features list endpoint.
      attr_accessor :active
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_accessor :metadata
      # The feature's name, for your own purpose, not meant to be displayable to the customer.
      attr_accessor :name

      def initialize(active: nil, expand: nil, metadata: nil, name: nil)
        @active = active
        @expand = expand
        @metadata = metadata
        @name = name
      end
    end
  end
end
