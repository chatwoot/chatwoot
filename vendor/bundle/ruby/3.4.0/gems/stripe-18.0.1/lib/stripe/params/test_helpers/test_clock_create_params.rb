# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module TestHelpers
    class TestClockCreateParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The initial frozen time for this test clock.
      attr_accessor :frozen_time
      # The name for this test clock.
      attr_accessor :name

      def initialize(expand: nil, frozen_time: nil, name: nil)
        @expand = expand
        @frozen_time = frozen_time
        @name = name
      end
    end
  end
end
