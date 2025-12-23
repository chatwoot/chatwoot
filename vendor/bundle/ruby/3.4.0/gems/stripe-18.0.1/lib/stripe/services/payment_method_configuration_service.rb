# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentMethodConfigurationService < StripeService
    # Creates a payment method configuration
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/payment_method_configurations",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # List payment method configurations
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/payment_method_configurations",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieve payment method configuration
    def retrieve(configuration, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/payment_method_configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Update payment method configuration
    def update(configuration, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/payment_method_configurations/%<configuration>s", { configuration: CGI.escape(configuration) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
