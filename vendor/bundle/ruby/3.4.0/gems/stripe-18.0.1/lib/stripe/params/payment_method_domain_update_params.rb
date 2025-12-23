# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodDomainUpdateParams < ::Stripe::RequestParams
    # Whether this payment method domain is enabled. If the domain is not enabled, payment methods that require a payment method domain will not appear in Elements or Embedded Checkout.
    attr_accessor :enabled
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(enabled: nil, expand: nil)
      @enabled = enabled
      @expand = expand
    end
  end
end
