# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  # You can configure [webhook endpoints](https://docs.stripe.com/webhooks/) via the API to be
  # notified about events that happen in your Stripe account or connected
  # accounts.
  #
  # Most users configure webhooks from [the dashboard](https://dashboard.stripe.com/webhooks), which provides a user interface for registering and testing your webhook endpoints.
  #
  # Related guide: [Setting up webhooks](https://docs.stripe.com/webhooks/configure)
  class WebhookEndpoint < APIResource
    extend Stripe::APIOperations::Create
    include Stripe::APIOperations::Delete
    extend Stripe::APIOperations::List
    include Stripe::APIOperations::Save

    OBJECT_NAME = "webhook_endpoint"
    def self.object_name
      "webhook_endpoint"
    end

    # The API version events are rendered as for this webhook endpoint.
    attr_reader :api_version
    # The ID of the associated Connect application.
    attr_reader :application
    # Time at which the object was created. Measured in seconds since the Unix epoch.
    attr_reader :created
    # An optional description of what the webhook is used for.
    attr_reader :description
    # The list of events to enable for this endpoint. `['*']` indicates that all events are enabled, except those that require explicit selection.
    attr_reader :enabled_events
    # Unique identifier for the object.
    attr_reader :id
    # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    attr_reader :livemode
    # Set of [key-value pairs](https://stripe.com/docs/api/metadata) that you can attach to an object. This can be useful for storing additional information about the object in a structured format.
    attr_reader :metadata
    # String representing the object's type. Objects of the same type share the same value.
    attr_reader :object
    # The endpoint's secret, used to generate [webhook signatures](https://docs.stripe.com/webhooks/signatures). Only returned at creation.
    attr_reader :secret
    # The status of the webhook. It can be `enabled` or `disabled`.
    attr_reader :status
    # The URL of the webhook endpoint.
    attr_reader :url
    # Always true for a deleted object
    attr_reader :deleted

    # A webhook endpoint must have a url and a list of enabled_events. You may optionally specify the Boolean connect parameter. If set to true, then a Connect webhook endpoint that notifies the specified url about events from all connected accounts is created; otherwise an account webhook endpoint that notifies the specified url only about events from your account is created. You can also create webhook endpoints in the [webhooks settings](https://dashboard.stripe.com/account/webhooks) section of the Dashboard.
    def self.create(params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: "/v1/webhook_endpoints",
        params: params,
        opts: opts
      )
    end

    # You can also delete webhook endpoints via the [webhook endpoint management](https://dashboard.stripe.com/account/webhooks) page of the Stripe dashboard.
    def self.delete(webhook_endpoint, params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/webhook_endpoints/%<webhook_endpoint>s", { webhook_endpoint: CGI.escape(webhook_endpoint) }),
        params: params,
        opts: opts
      )
    end

    # You can also delete webhook endpoints via the [webhook endpoint management](https://dashboard.stripe.com/account/webhooks) page of the Stripe dashboard.
    def delete(params = {}, opts = {})
      request_stripe_object(
        method: :delete,
        path: format("/v1/webhook_endpoints/%<webhook_endpoint>s", { webhook_endpoint: CGI.escape(self["id"]) }),
        params: params,
        opts: opts
      )
    end

    # Returns a list of your webhook endpoints.
    def self.list(params = {}, opts = {})
      request_stripe_object(method: :get, path: "/v1/webhook_endpoints", params: params, opts: opts)
    end

    # Updates the webhook endpoint. You may edit the url, the list of enabled_events, and the status of your endpoint.
    def self.update(webhook_endpoint, params = {}, opts = {})
      request_stripe_object(
        method: :post,
        path: format("/v1/webhook_endpoints/%<webhook_endpoint>s", { webhook_endpoint: CGI.escape(webhook_endpoint) }),
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
