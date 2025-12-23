# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerTaxIdService < StripeService
    # Creates a new tax_id object for a customer.
    def create(customer, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s/tax_ids", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Deletes an existing tax_id object.
    def delete(customer, id, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/customers/%<customer>s/tax_ids/%<id>s", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of tax IDs for a customer.
    def list(customer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/tax_ids", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves the tax_id object with the given identifier.
    def retrieve(customer, id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/tax_ids/%<id>s", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
