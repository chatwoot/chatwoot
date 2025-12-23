# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Radar
    class ValueListItemCreateParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The value of the item (whose type must match the type of the parent value list).
      attr_accessor :value
      # The identifier of the value list which the created item will be added to.
      attr_accessor :value_list

      def initialize(expand: nil, value: nil, value_list: nil)
        @expand = expand
        @value = value
        @value_list = value_list
      end
    end
  end
end
