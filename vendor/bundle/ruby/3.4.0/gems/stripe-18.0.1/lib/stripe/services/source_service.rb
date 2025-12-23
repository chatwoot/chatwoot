# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SourceService < StripeService
    attr_reader :transactions

    def initialize(requestor)
      super
      @transactions = Stripe::SourceTransactionService.new(@requestor)
    end

    # Creates a new source object.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/sources", params: params, opts: opts, base_address: :api)
    end

    # Delete a specified source for a given customer.
    def detach(customer, id, params = {}, opts = {})
      request(
        method: :delete,
        path: format("/v1/customers/%<customer>s/sources/%<id>s", { customer: CGI.escape(customer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Retrieves an existing source object. Supply the unique source ID from a source creation request and Stripe will return the corresponding up-to-date source object information.
    def retrieve(source, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/sources/%<source>s", { source: CGI.escape(source) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified source by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    #
    # This request accepts the metadata and owner as arguments. It is also possible to update type specific information for selected payment methods. Please refer to our [payment method guides](https://docs.stripe.com/docs/sources) for more detail.
    def update(source, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/sources/%<source>s", { source: CGI.escape(source) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Verify a given source.
    def verify(source, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/sources/%<source>s/verify", { source: CGI.escape(source) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
