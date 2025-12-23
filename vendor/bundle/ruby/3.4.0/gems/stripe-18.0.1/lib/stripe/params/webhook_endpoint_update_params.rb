# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class WebhookEndpointUpdateParams < ::Stripe::RequestParams
    # An optional description of what the webhook is used for.
    attr_accessor :description
    # Disable the webhook endpoint if set to true.
    attr_accessor :disabled
    # The list of events to enable for this endpoint. You may specify `['*']` to enable all events, except those that require explicit selection.
    attr_accessor :enabled_events
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The URL of the webhook endpoint.
    attr_accessor :url

    def initialize(
      description: nil,
      disabled: nil,
      enabled_events: nil,
      expand: nil,
      metadata: nil,
      url: nil
    )
      @description = description
      @disabled = disabled
      @enabled_events = enabled_events
      @expand = expand
      @metadata = metadata
      @url = url
    end
  end
end
