# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerPaymentSourceVerifyParams < ::Stripe::RequestParams
    # Two positive integers, in *cents*, equal to the values of the microdeposits sent to the bank account.
    attr_accessor :amounts
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(amounts: nil, expand: nil)
      @amounts = amounts
      @expand = expand
    end
  end
end
