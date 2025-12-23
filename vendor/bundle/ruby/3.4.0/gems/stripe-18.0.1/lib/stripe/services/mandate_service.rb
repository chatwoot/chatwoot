# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class MandateService < StripeService
    # Retrieves a Mandate object.
    def retrieve(mandate, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/mandates/%<mandate>s", { mandate: CGI.escape(mandate) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
