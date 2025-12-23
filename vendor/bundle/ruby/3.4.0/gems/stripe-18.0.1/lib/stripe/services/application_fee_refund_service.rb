# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ApplicationFeeRefundService < StripeService
    # Refunds an application fee that has previously been collected but not yet refunded.
    # Funds will be refunded to the Stripe account from which the fee was originally collected.
    #
    # You can optionally refund only part of an application fee.
    # You can do so multiple times, until the entire fee has been refunded.
    #
    # Once entirely refunded, an application fee can't be refunded again.
    # This method will raise an error when called on an already-refunded application fee,
    # or when trying to refund more money than is left on an application fee.
    def create(id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/application_fees/%<id>s/refunds", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # You can see a list of the refunds belonging to a specific application fee. Note that the 10 most recent refunds are always available by default on the application fee object. If you need more than those 10, you can use this API method and the limit and starting_after parameters to page through additional refunds.
    def list(id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/application_fees/%<id>s/refunds", { id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # By default, you can see the 10 most recent refunds stored directly on the application fee object, but you can also retrieve details about a specific refund stored on the application fee.
    def retrieve(fee, id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/application_fees/%<fee>s/refunds/%<id>s", { fee: CGI.escape(fee), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the specified application fee refund by setting the values of the parameters passed. Any parameters not provided will be left unchanged.
    #
    # This request only accepts metadata as an argument.
    def update(fee, id, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/application_fees/%<fee>s/refunds/%<id>s", { fee: CGI.escape(fee), id: CGI.escape(id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
