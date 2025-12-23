# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class AuthorizationRespondParams < ::Stripe::RequestParams
      # Whether to simulate the user confirming that the transaction was legitimate (true) or telling Stripe that it was fraudulent (false).
      attr_accessor :confirmed
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand

      def initialize(confirmed: nil, expand: nil)
        @confirmed = confirmed
        @expand = expand
      end
    end
  end
end
