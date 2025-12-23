# frozen_string_literal: true

require_relative '../analytics'

module Datadog
  module Tracing
    module Contrib
      module Shoryuken
        # Tracer is a Shoryuken server-side middleware which traces executed jobs
        class Tracer
          def initialize(options = {})
            @shoryuken_service = options[:service_name] || configuration[:service_name]
            @on_error = options[:on_error] || configuration[:on_error]
          end

          def call(worker_instance, queue, sqs_msg, body)
            Tracing.trace(
              Ext::SPAN_JOB,
              service: @shoryuken_service,
              type: Tracing::Metadata::Ext::AppTypes::TYPE_WORKER,
              on_error: @on_error
            ) do |span|
              span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_MESSAGING_SYSTEM)

              span.set_tag(Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_JOB)

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              span.resource = resource(worker_instance, body)
              span.set_tag(Ext::TAG_JOB_ID, sqs_msg.message_id)
              span.set_tag(Ext::TAG_JOB_QUEUE, queue)
              span.set_tag(Ext::TAG_JOB_ATTRIBUTES, sqs_msg.attributes) if sqs_msg.respond_to?(:attributes)
              span.set_tag(Ext::TAG_JOB_BODY, body) if configuration[:tag_body]

              span.set_tag(Tracing::Metadata::Ext::TAG_KIND, Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER)

              yield
            end
          end

          private

          def resource(worker_instance, body)
            # If it's a Hash, try to get the job class from it.
            # This is for ActiveJob compatibility.
            job_class = body['job_class'] if body.is_a?(Hash)
            # If nothing is available, use the worker class name.
            job_class || worker_instance.class.name
          end

          def configuration
            Datadog.configuration.tracing[:shoryuken]
          end
        end
      end
    end
  end
end
