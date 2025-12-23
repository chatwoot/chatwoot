# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class CustomerBalanceTransactionUpdateParams < ::Stripe::RequestParams
    # An arbitrary string attached to the object. Often useful for displaying to users.
    attr_accessor :description
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata

    def initialize(description: nil, expand: nil, metadata: nil)
      @description = description
      @expand = expand
      @metadata = metadata
    end
  end
end
