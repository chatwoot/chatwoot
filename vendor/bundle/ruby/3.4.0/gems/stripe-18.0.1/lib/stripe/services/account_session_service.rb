# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class AccountSessionService < StripeService
    # Creates a AccountSession object that includes a single-use token that the platform can use on their front-end to grant client-side API access.
    def create(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/account_sessions",
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
