# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Billing
    class MeterEventCreateParams < ::Stripe::RequestParams
      # The name of the meter event. Corresponds with the `event_name` field on a meter.
      attr_accessor :event_name
      # Specifies which fields in the response should be expanded.
      attr_accessor :expand
      # A unique identifier for the event. If not provided, one is generated. We recommend using UUID-like identifiers. We will enforce uniqueness within a rolling period of at least 24 hours. The enforcement of uniqueness primarily addresses issues arising from accidental retries or other problems occurring within extremely brief time intervals. This approach helps prevent duplicate entries and ensures data integrity in high-frequency operations.
      attr_accessor :identifier
      # The payload of the event. This must contain the fields corresponding to a meter's `customer_mapping.event_payload_key` (default is `stripe_customer_id`) and `value_settings.event_payload_key` (default is `value`). Read more about the [payload](https://docs.stripe.com/billing/subscriptions/usage-based/recording-usage#payload-key-overrides).
      attr_accessor :payload
      # The time of the event. Measured in seconds since the Unix epoch. Must be within the past 35 calendar days or up to 5 minutes in the future. Defaults to current timestamp if not specified.
      attr_accessor :timestamp

      def initialize(event_name: nil, expand: nil, identifier: nil, payload: nil, timestamp: nil)
        @event_name = event_name
        @expand = expand
        @identifier = identifier
        @payload = payload
        @timestamp = timestamp
      end
    end
  end
end
