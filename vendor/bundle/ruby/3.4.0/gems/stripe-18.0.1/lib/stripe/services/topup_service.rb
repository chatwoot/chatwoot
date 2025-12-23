# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TopupService < StripeService
    # Cancels a top-up. Only pending top-ups can be canceled.
    def cancel(topup, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/topups/%<topup>s/cancel", { topup: CGI.escape(topup) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Top up the balance of an account
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/topups", params: params, opts: opts, base_address: :api)
    end

    # Returns a list of top-ups.
    def list(params = {}, opts = {})
      request(method: :get, path: "/v1/topups", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the details of a top-up that has previously been created. Supply the unique top-up ID that was returned from your previous request, and Stripe will return the corresponding top-up information.
    def retrieve(topup, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/topups/%<topup>s", { topup: CGI.escape(topup) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates the metadata of a top-up. Other top-up details are not editable by design.
    def update(topup, params = {}, opts = {})
      request(
        method: :post,
        path: format("/v1/topups/%<topup>s", { topup: CGI.escape(topup) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
