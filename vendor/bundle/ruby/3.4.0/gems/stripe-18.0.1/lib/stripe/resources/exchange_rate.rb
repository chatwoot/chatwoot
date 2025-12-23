# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # [Deprecated] The `ExchangeRate` APIs are deprecated. Please use the [FX Quotes API](https://docs.stripe.com/payments/currencies/localize-prices/fx-quotes-api) instead.
  #
  # `ExchangeRate` objects allow you to determine the rates that Stripe is currently
  # using to convert from one currency to another. Since this number is variable
  # throughout the day, there are various reasons why you might want to know the current
  # rate (for example, to dynamically price an item for a user with a default
  # payment in a foreign currency).
  #
  # Please refer to our [Exchange Rates API](https://stripe.com/docs/fx-rates) guide for more details.
  #
  # *[Note: this integration path is supported but no longer recommended]* Additionally,
  # you can guarantee that a charge is made with an exchange rate that you expect is
  # current. To do so, you must pass in the exchange_rate to charges endpoints. If the
  # value is no longer up to date, the charge won't go through. Please refer to our
  # [Using with charges](https://stripe.com/docs/exchange-rates) guide for more details.
  #
  # -----
  #
  # &nbsp;
  #
  # *This Exchange Rates API is a Beta Service and is subject to Stripe's terms of service. You may use the API solely for the purpose of transacting on Stripe. For example, the API may be queried in order to:*
  #
  # - *localize prices for processing payments on Stripe*
  # - *reconcile Stripe transactions*
  # - *determine how much money to send to a connected account*
  # - *determine app fees to charge a connected account*
  #
  # *Using this Exchange Rates API beta for any purpose other than to transact on Stripe is strictly prohibited and constitutes a violation of Stripe's terms of service.*
  class ExchangeRate < APIResource
    extend Gem::Deprecate
    extend Stripe::APIOperations::List

    OBJECT_NAME = "exchange_rate"
    def self.object_name
      "exchange_rate"
    end

    # Unique identifier for the object. Represented as the three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html) in lowercase.
    attr_reader :id
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # Hash where the keys are supported currencies and the values are the exchange rate at which the base id currency converts to the key currency.
    attr_reader :rates

    # [Deprecated] The ExchangeRate APIs are deprecated. Please use the [FX Quotes API](https://docs.stripe.com/payments/currencies/localize-prices/fx-quotes-api) instead.
    #
    # Returns a list of objects that contain the rates at which foreign currencies are converted to one another. Only shows the currencies for which Stripe supports.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/exchange_rates", params: params, opts: opts)
    end

    class << self
      extend Gem::Deprecate
      deprecate :list, :none, 2024, 3
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
