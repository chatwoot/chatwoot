# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  class WebhookEndpointCreateParams < ::Stripe::RequestParams
    # Events sent to this endpoint will be generated with this Stripe Version instead of your account's default Stripe Version.
    attr_accessor :api_version
    # Whether this endpoint should receive events from connected accounts (`true`), or from your account (`false`). Defaults to `false`.
    attr_accessor :connect
    # An optional description of what the webhook is used for.
    attr_accessor :description
    # The list of events to enable for this endpoint. You may specify `['*']` to enable all events, except those that require explicit selection.
    attr_accessor :enabled_events
    # Specifies which fields in the response should be expanded.
    attr_accessor :expand
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format. Individual keys can be unset by posting an empty value to them. All keys can be unset by posting an empty value to `metadata`.
    attr_accessor :metadata
    # The URL of the webhook endpoint.
    attr_accessor :url

    def initialize(
      api_version: nil,
      connect: nil,
      description: nil,
      enabled_events: nil,
      expand: nil,
      metadata: nil,
      url: nil
    )
      @api_version = api_version
      @connect = connect
      @description = description
      @enabled_events = enabled_events
      @expand = expand
      @metadata = metadata
      @url = url
    end
  end
end
