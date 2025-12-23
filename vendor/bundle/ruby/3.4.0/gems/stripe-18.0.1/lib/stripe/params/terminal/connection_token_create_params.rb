# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Terminal
    class ConnectionTokenCreateParams < ::Stripe::RequestParams
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # The id of the location that this connection token is scoped to. If specified the connection token will only be usable with readers assigned to that location, otherwise the connection token will be usable with all readers. Note that location scoping only applies to internet-connected readers. For more details, see [the docs on scoping connection tokens](https://docs.stripe.com/terminal/fleet/locations-and-zones?dashboard-or-api=api#connection-tokens).
      attr_accessor :location

      def initialize(expand: nil, location: nil)
        @expand = expand
        @location = location
      end
    end
  end
end
