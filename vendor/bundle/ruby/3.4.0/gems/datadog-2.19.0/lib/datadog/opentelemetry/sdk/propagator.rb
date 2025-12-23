# frozen_string_literal: true

module Datadog
  module OpenTelemetry
    module SDK
      # Compatibility wrapper to allow Datadog propagators to fulfill the
      # OpenTelemetry propagator API.
      class Propagator
        def initialize(datadog_propagator)
          @datadog_propagator = datadog_propagator
        end

        def inject(
          carrier, context: ::OpenTelemetry::Context.current,
          setter: ::OpenTelemetry::Context::Propagation.text_map_setter
        )
          unless setter == ::OpenTelemetry::Context::Propagation.text_map_setter
            # PENDING: Not to report telemetry logs for now
            Datadog.logger.error(
              'Custom setter is not supported. Please inform the `datadog` team at ' \
            ' https://github.com/DataDog/dd-trace-rb of your use case so we can best support you. Using the default ' \
            'OpenTelemetry::Context::Propagation.text_map_setter as a fallback setter.'
            )
          end

          @datadog_propagator.inject(context.trace.to_digest, carrier)
        end

        def extract(
          carrier, context: ::OpenTelemetry::Context.current,
          getter: ::OpenTelemetry::Context::Propagation.text_map_getter
        )
          if getter != ::OpenTelemetry::Context::Propagation.text_map_getter &&
              getter != ::OpenTelemetry::Common::Propagation.rack_env_getter
            # PENDING: Not to report telemetry logs for now
            Datadog.logger.error(
              "Custom getter #{getter} is not supported. Please inform the `datadog` team at " \
            ' https://github.com/DataDog/dd-trace-rb of your use case so we can best support you. Using the default ' \
            'OpenTelemetry::Context::Propagation.text_map_getter as a fallback getter.'
            )
          end

          digest = @datadog_propagator.extract(carrier)
          return context unless digest

          # Converts the {Numeric} Datadog id object to OpenTelemetry's byte array format.
          # 128-bit unsigned, big-endian integer
          trace_id = [digest.trace_id >> 64, digest.trace_id & 0xFFFFFFFFFFFFFFFF].pack('Q>Q>')
          # 64-bit unsigned, big-endian integer
          span_id = [digest.span_id].pack('Q>')

          if digest.trace_state || digest.trace_flags
            trace_flags = ::OpenTelemetry::Trace::TraceFlags.from_byte(digest.trace_flags)
            tracestate = Tracing::Distributed::TraceContext.new(fetcher: nil).send(:build_tracestate, digest)
          else
            trace_flags = if Tracing::Sampling::PrioritySampler.sampled?(digest.trace_sampling_priority)
                            ::OpenTelemetry::Trace::TraceFlags::SAMPLED
                          else
                            ::OpenTelemetry::Trace::TraceFlags::DEFAULT
                          end
            tracestate = ::OpenTelemetry::Trace::Tracestate::DEFAULT
          end

          span_context = ::OpenTelemetry::Trace::SpanContext.new(
            trace_id: trace_id,
            span_id: span_id,
            trace_flags: trace_flags,
            tracestate: tracestate,
            remote: true
          )

          span = ::OpenTelemetry::Trace.non_recording_span(span_context)

          trace = Tracing.continue_trace!(digest)

          span.datadog_trace = trace

          ::OpenTelemetry::Trace.context_with_span(span, parent_context: context)
        end

        # Returns fields set by this propagator.
        # DEV: Doesn't seem like it's used in production Otel code paths.
        def fields
          []
        end
      end
    end
  end
end
