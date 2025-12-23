# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class TokenUpdateParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # Specifies which status the token should be updated to.
      attr_accessor :status

      def initialize(expand: nil, status: nil)
        @expand = expand
        @status = status
      end
    end
  end
end
