# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SourceVerifyParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # The values needed to verify the source.
    attr_accessor :values

    def initialize(expand: nil, values: nil)
      @expand = expand
      @values = values
    end
  end
end
