# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class CreditGrantUpdateParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The time when the billing credits created by this credit grant expire. If set to empty, the billing credits never expire.
      attr_accessor :expires_at
      # Set of key-value pairs you can attach to an object. You can use this to store additional information about the object (for example, cost basis) in a structured format.
      attr_accessor :metadata

      def initialize(expand: nil, expires_at: nil, metadata: nil)
        @expand = expand
        @expires_at = expires_at
        @metadata = metadata
      end
    end
  end
end
