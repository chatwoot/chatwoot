# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class QuoteFinalizeQuoteParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A future timestamp on which the quote will be canceled if in `open` or `draft` status. Measured in seconds since the Unix epoch.
    attr_accessor :expires_at

    def initialize(expand: nil, expires_at: nil)
      @expand = expand
      @expires_at = expires_at
    end
  end
end
