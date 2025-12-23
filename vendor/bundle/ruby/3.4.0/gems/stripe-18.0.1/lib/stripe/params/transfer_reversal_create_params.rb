# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class TransferReversalCreateParams < ::Stripe::RequestParams
    # A positive integer in cents (or local equivalent) representing how much of this transfer to reverse. Can only reverse up to the unreversed amount remaining of the transfer. Partial transfer reversals are only allowed for transfers to Stripe Accounts. Defaults to the entire transfer amount.
    attr_accessor :amount
    # An arbitrary string which you can attach to a reversal object. This will be unset if you POST an empty value.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # Boolean indicating whether the application fee should be refunded when reversing this transfer. If a full transfer reversal is given, the full application fee will be refunded. Otherwise, the application fee will be refunded with an amount proportional to the amount of the transfer reversed.
    attr_accessor :refund_application_fee

    def initialize(
      amount: nil,
      description: nil,
      expand: nil,
      metadata: nil,
      refund_application_fee: nil
    )
      @amount = amount
      @description = description
      @expand = expand
      @metadata = metadata
      @refund_application_fee = refund_application_fee
    end
  end
end
