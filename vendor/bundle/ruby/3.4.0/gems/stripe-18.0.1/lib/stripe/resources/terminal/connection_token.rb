# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    # A Connection Token is used by the Stripe Terminal SDK to connect to a reader.
    #
    # Related guide: [Fleet management](https://stripe.com/docs/terminal/fleet/locations)
    class ConnectionToken < APIResource
      extend Stripe::APIOperations::Create

      OBJECT_NAME = "terminal.connection_token"
      def self.object_name
        "terminal.connection_token"
      end

      # The id of the location that this connection token is scoped to. Note that location scoping only applies to internet-connected readers. For more details, see [the docs on scoping connection tokens](https://docs.stripe.com/terminal/fleet/locations-and-zones?dashboard-or-api=api#connection-tokens).
      attr_reader :location
      # String representing the object's type. Objects of the same type share the same value.
      attr_reader :object
      # Your application should pass this token to the Stripe Terminal SDK.
      attr_reader :secret

      # To connect to a reader the Stripe Terminal SDK needs to retrieve a short-lived connection token from Stripe, proxied through your server. On your backend, add an endpoint that creates and returns a connection token.
      def self.create(params = {}, opts = {})
        request_stripe_object(
          method: :post,
          path: "/v1/terminal/connection_tokens",
          params: params,
          opts: opts
        )
      end

      def self.inner_class_types
        @inner_class_types = {}
      end

      def self.field_remappings
        @field_remappings = {}
      end
    end
  end
end
