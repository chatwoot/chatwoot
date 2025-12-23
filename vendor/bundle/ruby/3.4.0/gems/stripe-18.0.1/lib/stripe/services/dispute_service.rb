# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class DisputeService < StripeService
    # Closing the dispute for a charge indicates that you do not have any evidence to submit and are essentially dismissing the dispute, acknowledging it as lost.
    #
    # The status of the dispute will change from needs_response to lost. Closing a dispute is irreversible.
    def close(dispute, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/disputes/%<dispute>s/close", { dispute: CGI.escape(dispute) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Returns a list of your disputes.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/disputes", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the dispute with the given ID.
    def retrieve(dispute, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/disputes/%<dispute>s", { dispute: CGI.escape(dispute) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # When you get a dispute, contacting your customer is always the best first step. If that doesn't work, you can submit evidence to help us resolve the dispute in your favor. You can do this in your [dashboard](https://dashboard.stripe.com/disputes), but if you prefer, you can use the API to submit evidence programmatically.
    #
    # Depending on your dispute type, different evidence fields will give you a better chance of winning your dispute. To figure out which evidence fields to provide, see our [guide to dispute types](https://docs.stripe.com/docs/disputes/categories).
    def update(dispute, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/disputes/%<dispute>s", { dispute: CGI.escape(dispute) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
