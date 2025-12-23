# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerPaymentSourceService < StripeService
    # When you create a new credit card, you must specify a customer or recipient on which to create it.
    #
    # If the card's owner has no default card, then the new card will become the default.
    # However, if the owner already has a default, then it will not change.
    # To change the default, you should [update the customer](https://docs.stripe.com/docs/api#update_customer) to have a new default_source.
    def create(customer, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s/sources", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Delete a specified source for a given customer.
    def delete(customer, id, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/customers/%<customer>s/sources/%<id>s", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # List sources for a specified customer.
    def list(customer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/sources", { customer: CGI.escape(customer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieve a specified source for a given customer.
    def retrieve(customer, id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/customers/%<customer>s/sources/%<id>s", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Update a specified source for a given customer.
    def update(customer, id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s/sources/%<id>s", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Verify a specified bank account for a given customer.
    def verify(customer, id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/customers/%<customer>s/sources/%<id>s/verify", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
