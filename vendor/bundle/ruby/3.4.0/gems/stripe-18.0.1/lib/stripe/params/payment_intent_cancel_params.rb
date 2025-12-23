# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class PaymentIntentCancelParams < ::Stripe::RequestParams
    # Reason for canceling this PaymentIntent. Possible values are: `duplicate`, `fraudulent`, `requested_by_customer`, or `abandoned`
    attr_accessor :cancellation_reason
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(cancellation_reason: nil, expand: nil)
      @cancellation_reason = cancellation_reason
      @expand = expand
    end
  end
end
