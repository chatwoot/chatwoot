# frozen_string_literal: true

require_relative '../../metadata/ext'
require_relative '../analytics'
require_relative 'ext'
require_relative 'utils'
require_relative '../utils/quantization/hash'
require_relative 'distributed/propagation'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        # Tracer is a Sidekiq server-side middleware which traces executed jobs
        class ServerTracer
          include Utils

          def initialize(options = {})
            @sidekiq_service = options[:service_name] || configuration[:service_name]
            @on_error = options[:on_error] || configuration[:on_error]
            @distributed_tracing = options[:distributed_tracing] || configuration[:distributed_tracing]
            @quantize = options[:quantize] || configuration[:quantize]
          end

          def call(worker, job, queue) # rubocop:disable Metrics/MethodLength
            resource = job_resource(job)

            if @distributed_tracing
              trace_digest = Sidekiq.extract(job)
              Datadog::Tracing.continue_trace!(trace_digest)
            end

            Datadog::Tracing.trace(
              Ext::SPAN_JOB,
              service: @sidekiq_service,
              type: Datadog::Tracing::Metadata::Ext::AppTypes::TYPE_WORKER,
              on_error: @on_error
            ) do |span|
              span.resource = resource

              span.set_tag(Contrib::Ext::Messaging::TAG_SYSTEM, Ext::TAG_COMPONENT)

              span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_COMPONENT, Ext::TAG_COMPONENT)
              span.set_tag(Datadog::Tracing::Metadata::Ext::TAG_OPERATION, Ext::TAG_OPERATION_JOB)

              span.set_tag(
                Datadog::Tracing::Metadata::Ext::TAG_KIND,
                Datadog::Tracing::Metadata::Ext::SpanKind::TAG_CONSUMER
              )

              # Set analytics sample rate
              if Contrib::Analytics.enabled?(configuration[:analytics_enabled])
                Contrib::Analytics.set_sample_rate(span, configuration[:analytics_sample_rate])
              end

              # Measure service stats
              Contrib::Analytics.set_measured(span)

              span.set_tag(Ext::TAG_JOB_ID, job['jid'])
              span.set_tag(Ext::TAG_JOB_RETRY, job['retry'])
              span.set_tag(Ext::TAG_JOB_RETRY_COUNT, job['retry_count'])
              span.set_tag(Ext::TAG_JOB_QUEUE, job['queue'])
              span.set_tag(Ext::TAG_JOB_WRAPPER, job['class']) if job['wrapped']

              enqueued_at = job['enqueued_at']
              enqueued_at *= Ext::SIDEKIQ_8_SECONDS_PER_INTEGER if enqueued_at.is_a?(Integer)
              span.set_tag(Ext::TAG_JOB_DELAY, 1000.0 * (Core::Utils::Time.now.utc.to_f - enqueued_at.to_f))

              args = job['args']
              if args && !args.empty?
                span.set_tag(Ext::TAG_JOB_ARGS, Contrib::Utils::Quantization::Hash.format(args, (@quantize[:args] || {})))
              end

              yield
            end
          end

          private

          def propagation
            @propagation ||= Contrib::Sidekiq::Distributed::Propagation.new
          end

          def configuration
            Datadog.configuration.tracing[:sidekiq]
          end
        end
      end
    end
  end
end
