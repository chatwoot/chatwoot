# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class SetupIntentRetrieveParams < ::Stripe::RequestParams
    # The client secret of the SetupIntent. We require this string if you use a publishable key to retrieve the SetupIntent.
    attr_accessor :client_secret
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand

    def initialize(client_secret: nil, expand: nil)
      @client_secret = client_secret
      @expand = expand
    end
  end
end
