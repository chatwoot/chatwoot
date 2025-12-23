# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      module DelayedJob
        module ServerInternalTracer
          # Trace when DelayedJob looks for a new job to work on
          module Worker
            def reserve_job
              configuration = Datadog.configuration.tracing[:delayed_job]

              Datadog::Tracing.trace(Ext::SPAN_RESERVE_JOB, service: configuration[:service_name]) do |span|
                span.type = Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER

                span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_COMPONENT)

                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
                span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_RESERVE_JOB)

                # Set analytics sample rate
                if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                  Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
                end

                super
              end
            end
          end
        end
      end
    end
  end
end
