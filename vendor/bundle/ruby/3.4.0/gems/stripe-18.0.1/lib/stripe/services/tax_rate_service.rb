# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxRateService < StripeService
    # Creates a new tax rate.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/tax_rates", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of your tax rates. Tax rates are returned sorted by creation date, with the most recently created tax rates appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/tax_rates", params: params, opts: opts, base_address: :api)
    end

    # Retrieves a tax rate with the given ID
    def retrieve(tax_rate, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/tax_rates/%<tax_rate>s", { tax_rate: CGI.escape(tax_rate) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates an existing tax rate.
    def update(tax_rate, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/tax_rates/%<tax_rate>s", { tax_rate: CGI.escape(tax_rate) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
