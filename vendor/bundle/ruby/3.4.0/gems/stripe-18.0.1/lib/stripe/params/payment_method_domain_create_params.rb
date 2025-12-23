# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodDomainCreateParams < ::Stripe::RequestParams
    # The domain name that this payment method domain object represents.
    attr_accessor :domain_name
    # Whether this payment method domain is enabled. If the domain is not enabled, payment methods that require a payment method domain will not appear in Elements or Embedded Checkout.
    attr_accessor :enabled
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(domain_name: nil, enabled: nil, expand: nil)
      @domain_name = domain_name
      @enabled = enabled
      @expand = expand
    end
  end
end
