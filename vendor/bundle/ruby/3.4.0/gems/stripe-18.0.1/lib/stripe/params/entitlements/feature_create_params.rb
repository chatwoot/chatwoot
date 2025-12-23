# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Entitlements
    class FeatureCreateParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A unique key you provide as your own system identifier. This may be up to 80 characters.
      attr_accessor :lookup_key
      # Set of key-value pairs that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
      attr_accessor :metadata
      # The feature's name, for your own purpose, not meant to be displayable to the customer.
      attr_accessor :name

      def initialize(expand: nil, lookup_key: nil, metadata: nil, name: nil)
        @expand = expand
        @lookup_key = lookup_key
        @metadata = metadata
        @name = name
      end
    end
  end
end
