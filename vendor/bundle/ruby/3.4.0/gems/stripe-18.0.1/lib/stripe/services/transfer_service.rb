# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TransferService < StripeService
    attr_reader :reversals

    def initialize(requestor)
      super
      @reversals = Stripe::TransferReversalService.new(@requestor)
    end

    # To send funds from your Stripe account to a connected account, you create a new transfer object. Your [Stripe balance](https://docs.stripe.com/api#balance) must be able to cover the transfer amount, or you'll receive an “Insufficient Funds” error.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/transfers", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of existing transfers sent to connected accounts. The transfers are returned in sorted order, with the most recently created transfers appearing first.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/transfers", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an existing transfer. Supply the unique transfer ID from either a transfer creation request or the transfer list, and Stripe will return the corresponding transfer information.
    def retrieve(transfer, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/transfers/%<transfer>s", { transfer: CGI.escape(transfer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified transfer by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    #
    # This request accepts only metadata as an argument.
    def update(transfer, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/transfers/%<transfer>s", { transfer: CGI.escape(transfer) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
