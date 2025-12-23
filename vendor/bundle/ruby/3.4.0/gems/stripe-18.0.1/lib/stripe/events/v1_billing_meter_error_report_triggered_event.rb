# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Events
    # Occurs when a Meter has invalid async usage events.
    class V1BillingMeterErrorReportTriggeredEvent < Stripe::V2::Core::Event
      def self.lookup_type
        "v1.billing.meter.error_report_triggered"
      end

      class V1BillingMeterErrorReportTriggeredEventData < ::Stripe::StripeObject
        class Reason < ::Stripe::StripeObject
          class ErrorType < ::Stripe::StripeObject
            class SampleError < ::Stripe::StripeObject
              class Request < ::Stripe::StripeObject
                # The request idempotency key.
                attr_reader :identifier

                def self.inner_class_types
                  @inner_class_types = {}
                end

                def self.field_remappings
                  @field_remappings = {}
                end
              end
              # The error message.
              attr_reader :error_message
              # The request causes the error.
              attr_reader :request

              def self.inner_class_types
                @inner_class_types = { request: Request }
              end

              def self.field_remappings
                @field_remappings = {}
              end
            end
            # Open Enum.
            attr_reader :code
            # The number of errors of this type.
            attr_reader :error_count
            # A list of sample errors of this type.
            attr_reader :sample_errors

            def self.inner_class_types
              @inner_class_types = { sample_errors: SampleError }
            end

            def self.field_remappings
              @field_remappings = {}
            end
          end
          # The total error count within this window.
          attr_reader :error_count
          # The error details.
          attr_reader :error_types

          def self.inner_class_types
            @inner_class_types = { error_types: ErrorType }
          end

          def self.field_remappings
            @field_remappings = {}
          end
        end
        # This contains information about why meter error happens.
        attr_reader :reason
        # Extra field included in the event's `data` when fetched from /v2/events.
        attr_reader :developer_message_summary
        # The start of the window that is encapsulated by this summary.
        attr_reader :validation_start
        # The end of the window that is encapsulated by this summary.
        attr_reader :validation_end

        def self.inner_class_types
          @inner_class_types = { reason: Reason }
        end

        def self.field_remappings
          @field_remappings = {}
        end
      end

      def self.inner_class_types
        @inner_class_types = { data: V1BillingMeterErrorReportTriggeredEventData }
      end
      attr_reader :data, :related_object

      # Retrieves the related object from the API. Makes an API request on every call.
      def fetch_related_object
        _request(
          method: :get,
          path: related_object.url,
          base_address: :api,
          opts: { stripe_context: context }
        )
      end
    end

    # Occurs when a Meter has invalid async usage events.
    class V1BillingMeterErrorReportTriggeredEventNotification < Stripe::V2::Core::EventNotification
      def self.lookup_type
        "v1.billing.meter.error_report_triggered"
      end

      attr_reader :related_object

      # Retrieves the Meter related to this EventNotification from the Stripe API. Makes an API request on every call.
      def fetch_related_object
        resp = @client.raw_request(
          :get,
          related_object.url,
          opts: { stripe_context: context },
          usage: ["fetch_related_object"]
        )
        @client.deserialize(resp.http_body, api_mode: Util.get_api_mode(related_object.url))
      end
    end
  end
end
