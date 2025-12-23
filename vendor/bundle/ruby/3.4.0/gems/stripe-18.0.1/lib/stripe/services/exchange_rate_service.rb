# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ExchangeRateService < StripeService
    # [Deprecated] The ExchangeRate APIs are deprecated. Please use the [FX Quotes API](https://docs.stripe.com/payments/currencies/localize-prices/fx-quotes-api) instead.
    #
    # Returns a list of objects that contain the rates at which foreign currencies are converted to one another. Only shows the currencies for which Stripe supports.
    def list(params = {}, opts = {})
      request(
        method: :get,
        path: "/v1/exchange_rates",
        params: params,
        opts: opts,
        base_address: :api
      )
    end

    # [Deprecated] The ExchangeRate APIs are deprecated. Please use the [FX Quotes API](https://docs.stripe.com/payments/currencies/localize-prices/fx-quotes-api) instead.
    #
    # Retrieves the exchange rates from the given currency to every supported currency.
    def retrieve(rate_id, params = {}, opts = {})
      request(
        method: :get,
        path: format("/v1/exchange_rates/%<rate_id>s", { rate_id: CGI.escape(rate_id) }),
        params: params,
        opts: opts,
        base_address: :api
      )
    end
  end
end
