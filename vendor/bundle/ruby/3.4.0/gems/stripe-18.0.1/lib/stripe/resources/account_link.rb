# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # Account Links are the means by which a Connect platform grants a connected account permission to access
  # Stripe-hosted applications, such as Connect Onboarding.
  #
  # Related guide: [Connect Onboarding](https://stripe.com/docs/connect/custom/hosted-onboarding)
  class AccountLink < APIResource
    extend Stripe::APIOperations::Create

    OBJECT_NAME = "account_link"
    def self.object_name
      "account_link"
    end

    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # The timestamp at which this account link will expire.
    attr_reader :expires_at
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The URL for the account link.
    attr_reader :url

    # Creates an AccountLink object that includes a single-use Stripe URL that the platform can redirect their user to in order to take them through the Connect Onboarding flow.
    def self.create(params = {}, opts = {})
      request_stripe_object(method: :post, path: "/v1/account_links", params: params, opts: opts)
    end

    def self.inner_class_types
      @inner_class_types = {}
    end

    def self.field_remappings
      @field_remappings = {}
    end
  end
end
