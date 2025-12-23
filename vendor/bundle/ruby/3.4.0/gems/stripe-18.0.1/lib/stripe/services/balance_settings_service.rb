# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class BalanceSettingsService < StripeService
    # Retrieves balance settings for a given connected account.
    #  Related guide: [Making API calls for connected accounts](https://docs.stripe.com/connect/authentication)
    def retrieve(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/balance_settings",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # Updates balance settings for a given connected account.
    #  Related guide: [Making API calls for connected accounts](https://docs.stripe.com/connect/authentication)
    def update(params = {}, opts = {})
      request(
        method: :post,
        path: "/v1/balance_settings",
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
