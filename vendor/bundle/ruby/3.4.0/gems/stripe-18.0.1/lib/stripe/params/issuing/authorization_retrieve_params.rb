# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Issuing
    class AuthorizationRetrieveParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand

      def initialize(expand: nil)
        @expand = expand
      end
    end
  end
end
