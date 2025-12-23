# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CountrySpecService < StripeService
    # Lists all Country Spec objects available in the API.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/country_specs",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a Country Spec for a given Country code.
    def retrieve(country, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/country_specs/%<country>s", { country: CGI.escape(country) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
