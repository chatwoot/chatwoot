# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxCodeService < StripeService
    # A list of [all tax codes available](https://stripe.com/docs/tax/tax-categories) to add to Products in order to allow specific tax calculations.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/tax_codes", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an existing tax code. Supply the unique tax code ID and Stripe will return the corresponding tax code information.
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/tax_codes/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
