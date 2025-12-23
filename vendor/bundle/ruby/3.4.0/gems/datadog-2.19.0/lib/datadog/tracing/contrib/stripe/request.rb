# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../../analytics'
require_relative 'ext'

module Datadog
  module Tracing
    module Contrib
      module Stripe
        # Defines instrumentation for Stripe requests
        module Request
          module_function

          def start_span(event)
            # Start a trace
            Tracing.trace(Ext::SPAN_REQUEST).tap do |span|
              event.user_data[:datadog_span] = span
            end
          end

          def finish_span(event)
            span = event.user_data[:datadog_span]
            # If no active span, return.
            return nil if span.nil?

            begin
              tag_span(span, event)
            ensure
              # Finish the span
              span.finish
            end
          end

          def tag_span(span, event)
            # dependent upon stripe/stripe-ruby#1168
            span.resource = "stripe.#{event.object_name}" if event.respond_to?(:object_name) && event.object_name

            span.type = Ext::SPAN_TYPE_REQUEST
            span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
            span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_REQUEST)

            # Set analytics sample rate
            if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
              Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
            end

            # Measure service stats
            Contrib::Analytics.set_measured(span)
            # `5.38.0` Add request_id to RequestEndEvent
            # https://github.com/stripe/stripe-ruby/blob/master/CHANGELOG.md#5380---2021-08-10
            span.set_tag(Ext::TAG_REQUEST_ID, event.request_id) if event.respond_to?(:request_id)
            span.set_tag(Ext::TAG_REQUEST_HTTP_STATUS, event.http_status.to_s)
            span.set_tag(Ext::TAG_REQUEST_METHOD, event.method)
            span.set_tag(Ext::TAG_REQUEST_PATH, event.path)
            span.set_tag(Ext::TAG_REQUEST_NUM_RETRIES, event.num_retries.to_s)
          rescue StandardError => e
            Datadog.logger.debug(e.message)
          end

          def configuration
            Datadog.configuration.tracing[:stripe]
          end
        end
      end
    end
  end
end
