# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module V2
    module Core
      # Set up an event destination to receive events from Stripe across multiple destination types, including [webhook endpoints](https://docs.stripe.com/webhooks) and [Amazon EventBridge](https://docs.stripe.com/event-destinations/eventbridge). Event destinations support receiving [thin events](https://docs.stripe.com/api/v2/events) and [snapshot events](https://docs.stripe.com/api/events).
      class EventDestination < APIResource
        OBJECT_NAME = "v2.core.event_destination"
        def self.object_name
          "v2.core.event_destination"
        end

        class StatusDetails < ::Stripe::StripeObject
          class Disabled < ::Stripe::StripeObject
            # Reason event destination has been disabled.
            attr_reader :reason

            def self.inner_class_types
              @inner_class_types = {}
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # Details about why the event destination has been disabled.
          attr_reader :disabled

          def self.inner_class_types
            @inner_class_types = { disabled: Disabled }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class AmazonEventbridge < ::Stripe::StripeObject
          # The AWS account ID.
          attr_reader :aws_account_id
          # The ARN of the AWS event source.
          attr_reader :aws_event_source_arn
          # The state of the AWS event source.
          attr_reader :aws_event_source_status

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end

        class WebhookEndpoint < ::Stripe::StripeObject
          # The signing secret of the webhook endpoint, only includable on creation.
          attr_reader :signing_secret
          # The URL of the webhook endpoint, includable.
          attr_reader :url

          def self.inner_class_types
            @inner_class_types = {}
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # Time at which the object was created.
        attr_reader :created
        # An optional description of what the event destination is used for.
        attr_reader :description
        # The list of events to enable for this endpoint.
        attr_reader :enabled_events
        # Payload type of events being subscribed to.
        attr_reader :event_payload
        # Where events should be routed from.
        attr_reader :events_from
        # Unique identifier for the object.
        attr_reader :id
        # Metadata.
        attr_reader :metadata
        # Event destination name.
        attr_reader :name
        # String representing the object's type. Objects of the same type share the same value of the object field.
        attr_reader :object
        # If using the snapshot event payload, the API version events are rendered as.
        attr_reader :snapshot_api_version
        # Status. It can be set to either enabled or disabled.
        attr_reader :status
        # Additional information about event destination status.
        attr_reader :status_details
        # Event destination type.
        attr_reader :type
        # Time at which the object was last updated.
        attr_reader :updated
        # Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
        attr_reader :livemode
        # Amazon EventBridge configuration.
        attr_reader :amazon_eventbridge
        # Webhook endpoint configuration.
        attr_reader :webhook_endpoint

        def self.inner_class_types
          @inner_class_types = {
            status_details: StatusDetails,
            amazon_eventbridge: AmazonEventbridge,
            webhook_endpoint: WebhookEndpoint,
          }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end
    end
  end
end
