# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class RefundService < StripeService
    # Cancels a refund with a status of requires_action.
    #
    # You can't cancel refunds in other states. Only refunds for payment methods that require customer action can enter the requires_action state.
    def cancel(refund, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/refunds/%<refund>s/cancel", { refund: CGI.escape(refund) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # When you create a new refund, you must specify a Charge or a PaymentIntent object on which to create it.
    #
    # Creating a new refund will refund a charge that has previously been created but not yet refunded.
    # Funds will be refunded to the credit or debit card that was originally charged.
    #
    # You can optionally refund only part of a charge.
    # You can do so multiple times, until the entire charge has been refunded.
    #
    # Once entirely refunded, a charge can't be refunded again.
    # This method will raise an error when called on an already-refunded charge,
    # or when trying to refund more money than is left on a charge.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/refunds", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of all refunds you created. We return the refunds in sorted order, with the most recent refunds appearing first. The 10 most recent refunds are always available by default on the Charge object.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/refunds", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of an existing refund.
    def retrieve(refund, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/refunds/%<refund>s", { refund: CGI.escape(refund) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the refund that you specify by setting the values of the passed parameters. Any parameters that you don't provide remain unchanged.
    #
    # This request only accepts metadata as an argument.
    def update(refund, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/refunds/%<refund>s", { refund: CGI.escape(refund) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
