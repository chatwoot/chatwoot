# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module FinancialConnections
    class AccountRefreshAccountParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The list of account features that you would like to refresh.
      attr_accessor :features

      def initialize(expand: nil, features: nil)
        @expand = expand
        @features = features
      end
    end
  end
end
