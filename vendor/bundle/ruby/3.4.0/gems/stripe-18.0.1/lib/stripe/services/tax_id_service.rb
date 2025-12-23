# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TaxIdService < StripeService
    # Creates a new account or customer tax_id object.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/tax_ids", params: params, opts: opts, base_address: :api)
    end

    # Deletes an existing account or customer tax_id object.
    def delete(id, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/tax_ids/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of tax IDs.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/tax_ids", params: params, opts: opts, base_address: :api)
    end

    # Retrieves an account or customer tax_id object.
    def retrieve(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/tax_ids/%<id>s", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
