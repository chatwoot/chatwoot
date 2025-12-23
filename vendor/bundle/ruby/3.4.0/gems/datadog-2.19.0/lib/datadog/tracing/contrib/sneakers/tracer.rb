# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      module Sneakers
        # Tracer is a Sneakers server-side middleware which traces executed jobs
        class Tracer
          def initialize(app, *args)
            @app = app
            @args = args
          end

          def call(deserialized_msg, delivery_info, metadata, handler)
            trace_options = {
              service: configuration[:service_name],
              type: Tracing::Metadata::Ext::AppTypes::TYPE_WORKER,
              on_error: configuration[:on_error]
            }

            Tracing.trace(Ext::SPAN_JOB, **trace_options) do |request_span|
              request_span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_MESSAGING_SYSTEM)

              request_span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              request_span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_JOB)

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(request_span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(request_span)

              request_span.resource = @app.to_proc.binding.eval('self.class').to_s
              request_span.set_tag(Ext::TAG_JOB_ROUTING_KEY, delivery_info.routing_key)
              request_span.set_tag(Ext::TAG_RABBITMQ_ROUTING_KEY, delivery_info.routing_key)
              request_span.set_tag(Ext::TAG_JOB_QUEUE, delivery_info.consumer.queue.name)

              request_span.set_tag(Ext::TAG_JOB_BODY, deserialized_msg) if configuration[:tag_body]

              request_span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER)

              @app.call(deserialized_msg, delivery_info, metadata, handler)
            end
          end

          private

          def configuration
            Datadog.configuration.tracing[:sneakers]
          end
        end
      end
    end
  end
end
