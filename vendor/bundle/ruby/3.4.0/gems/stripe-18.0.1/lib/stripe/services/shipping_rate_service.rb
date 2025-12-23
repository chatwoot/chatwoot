# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ShippingRateService < StripeService
    # Creates a new shipping rate object.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/shipping_rates",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your shipping rates.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/shipping_rates",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns the shipping rate object with the given ID.
    def retrieve(shipping_rate_token, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/shipping_rates/%<shipping_rate_token>s", { shipping_rate_token: CGI.escape(shipping_rate_token) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates an existing shipping rate object.
    def update(shipping_rate_token, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/shipping_rates/%<shipping_rate_token>s", { shipping_rate_token: CGI.escape(shipping_rate_token) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
