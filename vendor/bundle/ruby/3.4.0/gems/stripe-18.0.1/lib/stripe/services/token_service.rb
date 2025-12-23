# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TokenService < StripeService
    # Creates a single-use token that represents a bank account's details.
    # You can use this token with any v1 API method in place of a bank account dictionary. You can only use this token once. To do so, attach it to a [connected account](https://docs.stripe.com/api#accounts) where [controller.requirement_collection](https://docs.stripe.com/api/accounts/object#account_object-controller-requirement_collection) is application, which includes Custom accounts.
    def create(params = {}, opts = {})
      request(method: :post, path: "/v1/tokens", params: params, opts: opts, base_address: :api)
    end

    # Retrieves the token with the given ID.
    def retrieve(token, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/tokens/%<token>s", { token: CGI.escape(token) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
