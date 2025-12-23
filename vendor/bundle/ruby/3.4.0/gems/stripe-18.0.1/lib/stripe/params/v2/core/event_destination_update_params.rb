# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Core
      class EventDestinationUpdateParams < ::Stripe::RequestParams
        class WebhookEndpoint < ::Stripe::RequestParams
          # The URL of the webhook endpoint.
          attr_accessor :url

          def initialize(url: nil)
            @url = url
          end
        end
        # An optional description of what the event destination is used for.
        attr_accessor :description
        # The list of events to enable for this endpoint.
        attr_accessor :enabled_events
        # Additional fields to include in the response. Currently supports `webhook_endpoint.url`.
        attr_accessor :include
        # Metadata.
        attr_accessor :metadata
        # Event destination name.
        attr_accessor :name
        # Webhook endpoint configuration.
        attr_accessor :webhook_endpoint

        def initialize(
          description: nil,
          enabled_events: nil,
          include: nil,
          metadata: nil,
          name: nil,
          webhook_endpoint: nil
        )
          @description = description
          @enabled_events = enabled_events
          @include = include
          @metadata = metadata
          @name = name
          @webhook_endpoint = webhook_endpoint
        end
      end
    end
  end
end
