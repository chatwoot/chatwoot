# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ApplePayDomainCreateParams < ::Stripe::RequestParams
    # Attribute for param field domain_name
    attr_accessor :domain_name
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(domain_name: nil, expand: nil)
      @domain_name = domain_name
      @expand = expand
    end
  end
end
