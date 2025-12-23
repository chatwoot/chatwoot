# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class RefundCreateParams < ::Stripe::RequestParams
    # Attribute for param field amount
    attr_accessor :amount
    # The identifier of the charge to refund.
    attr_accessor :charge
    # Three-letter [ISO currency code](https://www.iso.org/iso-4217-currency-codes.html), in lowercase. Must be a [supported currency](https://stripe.com/docs/currencies).
    attr_accessor :currency
    # Customer whose customer balance to refund from.
    attr_accessor :customer
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # For payment methods without native refund support (e.g., Konbini, PromptPay), use this email from the customer to receive refund instructions.
    attr_accessor :instructions_email
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Origin of the refund
    attr_accessor :origin
    # The identifier of the PaymentIntent to refund.
    attr_accessor :payment_intent
    # String indicating the reason for the refund. If set, possible values are `duplicate`, `fraudulent`, and `requested_by_customer`. If you believe the charge to be fraudulent, specifying `fraudulent` as the reason will add the associated card and email to your [block lists](https://stripe.com/docs/radar/lists), and will also help us improve our fraud detection algorithms.
    attr_accessor :reason
    # Boolean indicating whether the application fee should be refunded when refunding this charge. If a full charge refund is given, the full application fee will be refunded. Otherwise, the application fee will be refunded in an amount proportional to the amount of the charge refunded. An application fee can be refunded only by the application that created the charge.
    attr_accessor :refund_application_fee
    # Boolean indicating whether the transfer should be reversed when refunding this charge. The transfer will be reversed proportionally to the amount being refunded (either the entire or partial amount).<br><br>A transfer can be reversed only by the application that created the charge.
    attr_accessor :reverse_transfer

    def initialize(
      amount: nil,
      charge: nil,
      currency: nil,
      customer: nil,
      expand: nil,
      instructions_email: nil,
      metadata: nil,
      origin: nil,
      payment_intent: nil,
      reason: nil,
      refund_application_fee: nil,
      reverse_transfer: nil
    )
      @amount = amount
      @charge = charge
      @currency = currency
      @customer = customer
      @expand = expand
      @instructions_email = instructions_email
      @metadata = metadata
      @origin = origin
      @payment_intent = payment_intent
      @reason = reason
      @refund_application_fee = refund_application_fee
      @reverse_transfer = reverse_transfer
    end
  end
end
