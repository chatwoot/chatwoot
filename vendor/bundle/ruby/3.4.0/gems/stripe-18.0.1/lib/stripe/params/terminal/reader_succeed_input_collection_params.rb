# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ReaderSucceedInputCollectionParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # This parameter defines the skip behavior for input collection.
      attr_accessor :skip_non_required_inputs

      def initialize(expand: nil, skip_non_required_inputs: nil)
        @expand = expand
        @skip_non_required_inputs = skip_non_required_inputs
      end
    end
  end
end
