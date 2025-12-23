# File generated from our OpenAPI spec
# frozen_string_literal: true

module Stripe
  module Events
    # Occurs when a Meter's id is missing or invalid in async usage events.
    class V1BillingMeterNoMeterFoundEvent < Stripe::V2::Core::Event
      def self.lookup_type
        "v1.billing.meter.no_meter_found"
      end

      class V1BillingMeterNoMeterFoundEventData < ::Stripe::StripeObject
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
        @inner_class_types = { data: V1BillingMeterNoMeterFoundEventData }
      end
      attr_reader :data
    end

    # Occurs when a Meter's id is missing or invalid in async usage events.
    class V1BillingMeterNoMeterFoundEventNotification < Stripe::V2::Core::EventNotification
      def self.lookup_type
        "v1.billing.meter.no_meter_found"
      end
    end
  end
end
