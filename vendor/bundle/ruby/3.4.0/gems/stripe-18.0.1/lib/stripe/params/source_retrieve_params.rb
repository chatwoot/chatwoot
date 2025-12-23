# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SourceRetrieveParams < ::Stripe::RequestParams
    # The client secret of the source. Required if a publishable key is used to retrieve the source.
    attr_accessor :client_secret
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(client_secret: nil, expand: nil)
      @client_secret = client_secret
      @expand = expand
    end
  end
end
