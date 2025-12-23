# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodAttachParams < ::Stripe::RequestParams
    # The ID of the customer to which to attach the PaymentMethod.
    attr_accessor :customer
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(customer: nil, expand: nil)
      @customer = customer
      @expand = expand
    end
  end
end
