# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerPaymentMethodService < StripeService
    # Returns a list of PaymentMethods for a given Customer
    def list(customer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/payment_methods", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves a PaymentMethod object for a given Customer.
    def retrieve(customer, payment_method, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/payment_methods/%<payment_method>s", { customer: CGI.escape(customer), payment_method: CGI.escape(payment_method) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
