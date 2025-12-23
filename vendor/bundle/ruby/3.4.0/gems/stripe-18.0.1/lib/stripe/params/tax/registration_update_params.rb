# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Tax
    class RegistrationUpdateParams < ::Stripe::RequestParams
      # Time at which the registration becomes active. It can be either `now` to indicate the current time, or a timestamp measured in seconds since the Unix epoch.
      attr_accessor :active_from
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # If set, the registration stops being active at this time. If not set, the registration will be active indefinitely. It can be either `now` to indicate the current time, or a timestamp measured in seconds since the Unix epoch.
      attr_accessor :expires_at

      def initialize(active_from: nil, expand: nil, expires_at: nil)
        @active_from = active_from
        @expand = expand
        @expires_at = expires_at
      end
    end
  end
end
