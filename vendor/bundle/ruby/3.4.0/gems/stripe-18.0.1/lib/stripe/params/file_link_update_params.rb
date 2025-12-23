# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class FileLinkUpdateParams < ::Stripe::RequestParams
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # A future timestamp after which the link will no longer be usable, or `now` to expire the link immediately.
    attr_accessor :expires_at
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata

    def initialize(expand: nil, expires_at: nil, metadata: nil)
      @expand = expand
      @expires_at = expires_at
      @metadata = metadata
    end
  end
end
