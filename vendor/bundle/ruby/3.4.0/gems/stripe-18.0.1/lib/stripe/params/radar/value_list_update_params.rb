# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    class ValueListUpdateParams < ::Stripe::RequestParams
      # The name of the value list for use in rules.
      attr_accessor :alias
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
      attr_accessor :metadata
      # The human-readable name of the value list.
      attr_accessor :name

      def initialize(alias_: nil, expand: nil, metadata: nil, name: nil)
        @alias = alias_
        @expand = expand
        @metadata = metadata
        @name = name
      end
    end
  end
end
