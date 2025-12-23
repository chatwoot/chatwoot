# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterUpdateParams < ::Stripe::RequestParams
      # The meter’s name. Not visible to the customer.
      attr_accessor :display_name
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand

      def initialize(display_name: nil, expand: nil)
        @display_name = display_name
        @expand = expand
      end
    end
  end
end
