# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Reporting
    class ReportRunRetrieveParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand

      def initialize(expand: nil)
        @expand = expand
      end
    end
  end
end
