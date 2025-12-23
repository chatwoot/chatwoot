# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CreditNoteUpdateParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Credit note memo.
    attr_accessor :memo
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata

    def initialize(expand: nil, memo: nil, metadata: nil)
      @expand = expand
      @memo = memo
      @metadata = metadata
    end
  end
end
