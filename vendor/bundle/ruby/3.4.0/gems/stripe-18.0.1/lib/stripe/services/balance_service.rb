# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class BalanceService < StripeService
    # Retrieves the current account balance, based on the authentication that was used to make the request.
    #  For a sample request, see [Accounting for negative balances](https://docs.stripe.com/docs/connect/account-balances#accounting-for-negative-balances).
    def retrieve(params = {}, opts = {})
      request(method: :get, path: "/v1/balance", params: params, opts: opts, base_address: :api)
    end
  end
end
