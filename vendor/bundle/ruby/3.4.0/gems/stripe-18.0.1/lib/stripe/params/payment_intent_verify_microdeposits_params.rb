# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntentVerifyMicrodepositsParams < ::Stripe::RequestParams
    # Two positive integers, in *cents*, equal to the values of the microdeposits sent to the bank account.
    attr_accessor :amounts
    # A six-character code starting with SM present in the microdeposit sent to the bank account.
    attr_accessor :descriptor_code
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(amounts: nil, descriptor_code: nil, expand: nil)
      @amounts = amounts
      @descriptor_code = descriptor_code
      @expand = expand
    end
  end
end
