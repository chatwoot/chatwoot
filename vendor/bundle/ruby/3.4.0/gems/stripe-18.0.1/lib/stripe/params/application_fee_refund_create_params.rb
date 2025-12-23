# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class ApplicationFeeRefundCreateParams < ::Stripe::RequestParams
    # A positive integer, in _cents (or local equivalent)_, representing how much of this fee to refund. Can refund only up to the remaining unrefunded amount of the fee.
    attr_accessor :amount
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata

    def initialize(amount: nil, expand: nil, metadata: nil)
      @amount = amount
      @expand = expand
      @metadata = metadata
    end
  end
end
