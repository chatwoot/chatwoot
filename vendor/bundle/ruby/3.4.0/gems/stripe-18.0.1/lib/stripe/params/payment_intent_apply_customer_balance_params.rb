# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntentApplyCustomerBalanceParams < ::Stripe::RequestParams
    # Amount that you intend to apply to this PaymentIntent from the customer’s cash balance. If the PaymentIntent was created by an Invoice, the full amount of the PaymentIntent is applied regardless of this parameter.
    #
    # A positive integer representing how much to charge in the [smallest currency unit](https://stripe.com/docs/currencies#zero-decimal) (for example, 100 cents to charge 1 USD or 100 to charge 100 JPY, a zero-decimal currency). The maximum amount is the amount of the PaymentIntent.
    #
    # When you omit the amount, it defaults to the remaining amount requested on the PaymentIntent.
    attr_accessor :amount
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(amount: nil, currency: nil, expand: nil)
      @amount = amount
      @currency = currency
      @expand = expand
    end
  end
end
