# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TransferReversalService < StripeService
    # When you create a new reversal, you must specify a transfer to create it on.
    #
    # When reversing transfers, you can optionally reverse part of the transfer. You can do so as many times as you wish until the entire transfer has been reversed.
    #
    # Once entirely reversed, a transfer can't be reversed again. This method will return an error when called on an already-reversed transfer, or when trying to reverse more money than is left on a transfer.
    def create(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/transfers/%<id>s/reversals", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # You can see a list of the reversals belonging to a specific transfer. Note that the 10 most recent reversals are always available by default on the transfer object. If you need more than those 10, you can use this API method and the limit and starting_after parameters to page through additional reversals.
    def list(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/transfers/%<id>s/reversals", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # By default, you can see the 10 most recent reversals stored directly on the transfer object, but you can also retrieve details about a specific reversal stored on the transfer.
    def retrieve(transfer, id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/transfers/%<transfer>s/reversals/%<id>s", { transfer: CGI.escape(transfer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified reversal by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    #
    # This request only accepts metadata and description as arguments.
    def update(transfer, id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/transfers/%<transfer>s/reversals/%<id>s", { transfer: CGI.escape(transfer), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
