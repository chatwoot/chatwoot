# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # {TracerProvider} is the SDK implementation of {OpenTelemetry::Trace::TracerProvider}.
      class TracerProvider < OpenTelemetry::Trace::TracerProvider # rubocop:disable Metrics/ClassLength
        Key = Struct.new(:name, :version)
        private_constant(:Key)

        attr_accessor :span_limits, :id_generator, :sampler
        attr_reader :resource

        # Returns a new {TracerProvider} instance.
        #
        # @param [optional Sampler] sampler The sampling policy for new spans
        # @param [optional Resource] resource The resource to associate with spans
        #   created by Tracers created by this TracerProvider
        # @param [optional IDGenerator] id_generator The trace and span ID generation
        #   policy
        # @param [optional SpanLimits] span_limits The limits to apply to attribute,
        #   event and link counts for Spans created by Tracers created by this
        #   TracerProvider
        #
        # @return [TracerProvider]
        def initialize(sampler: sampler_from_environment(Samplers.parent_based(root: Samplers::ALWAYS_ON)),
                       resource: OpenTelemetry::SDK::Resources::Resource.create,
                       id_generator: OpenTelemetry::Trace,
                       span_limits: SpanLimits::DEFAULT)
          @mutex = Mutex.new
          @registry = {}
          @registry_mutex = Mutex.new
          @span_processors = []
          @span_limits = span_limits
          @sampler = sampler
          @id_generator = id_generator
          @stopped = false
          @resource = resource
        end

        # Returns a {Tracer} instance.
        #
        # @param [optional String] name Instrumentation package name
        # @param [optional String] version Instrumentation package version
        #
        # @return [Tracer]
        def tracer(name = nil, version = nil)
          name ||= ''
          version ||= ''
          OpenTelemetry.logger.warn 'calling TracerProvider#tracer without providing a tracer name.' if name.empty?
          @registry_mutex.synchronize { @registry[Key.new(name, version)] ||= Tracer.new(name, version, self) }
        end

        # Attempts to stop all the activity for this {TracerProvider}. Calls
        # SpanProcessor#shutdown for all registered SpanProcessors.
        #
        # This operation may block until all the Spans are processed. Must be
        # called before turning off the main application to ensure all data are
        # processed and exported.
        #
        # After this is called all the newly created {Span}s will be no-op.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling Tracer#shutdown multiple times.')
              return Export::FAILURE
            end

            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @span_processors.map do |processor|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              break [Export::TIMEOUT] if remaining_timeout&.zero?

              processor.shutdown(timeout: remaining_timeout)
            end
            @stopped = true
            results.max || Export::SUCCESS
          end
        end

        # Immediately export all spans that have not yet been exported for all the
        # registered SpanProcessors.
        #
        # This method should only be called in cases where it is absolutely
        # necessary, such as when using some FaaS providers that may suspend
        # the process after an invocation, but before the `Processor` exports
        # the completed spans.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def force_flush(timeout: nil)
          @mutex.synchronize do
            return Export::SUCCESS if @stopped

            start_time = OpenTelemetry::Common::Utilities.timeout_timestamp
            results = @span_processors.map do |processor|
              remaining_timeout = OpenTelemetry::Common::Utilities.maybe_timeout(timeout, start_time)
              return Export::TIMEOUT if remaining_timeout&.zero?

              processor.force_flush(timeout: remaining_timeout)
            end
            results.max || Export::SUCCESS
          end
        end

        # Adds a new SpanProcessor to this {Tracer}.
        #
        # @param span_processor the new SpanProcessor to be added.
        def add_span_processor(span_processor)
          @mutex.synchronize do
            if @stopped
              OpenTelemetry.logger.warn('calling Tracer#add_span_processor after shutdown.')
              return
            end
            @span_processors = @span_processors.dup.push(span_processor)
          end
        end

        # @api private
        def internal_start_span(name, kind, attributes, links, start_timestamp, parent_context, instrumentation_scope) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
          parent_span = OpenTelemetry::Trace.current_span(parent_context)
          parent_span_context = parent_span.context

          if parent_span_context.valid?
            parent_span_id = parent_span_context.span_id
            trace_id = parent_span_context.trace_id
          end
          trace_id ||= @id_generator.generate_trace_id

          if OpenTelemetry::Common::Utilities.untraced?(parent_context)
            span_id = parent_span_id || @id_generator.generate_span_id
            return OpenTelemetry::Trace.non_recording_span(OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id))
          end

          result = @sampler.should_sample?(trace_id: trace_id, parent_context: parent_context, links: links, name: name, kind: kind, attributes: attributes)
          span_id = @id_generator.generate_span_id
          if result.recording? && !@stopped
            trace_flags = result.sampled? ? OpenTelemetry::Trace::TraceFlags::SAMPLED : OpenTelemetry::Trace::TraceFlags::DEFAULT
            context = OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id, trace_flags: trace_flags, tracestate: result.tracestate)
            attributes = attributes&.merge(result.attributes) || result.attributes.dup
            Span.new(
              context,
              parent_context,
              parent_span,
              name,
              kind,
              parent_span_id,
              @span_limits,
              @span_processors,
              attributes,
              links,
              start_timestamp,
              @resource,
              instrumentation_scope
            )
          else
            OpenTelemetry::Trace.non_recording_span(OpenTelemetry::Trace::SpanContext.new(trace_id: trace_id, span_id: span_id, tracestate: result.tracestate))
          end
        end

        private

        def sampler_from_environment(default_sampler)
          case ENV['OTEL_TRACES_SAMPLER']
          when 'always_on' then Samplers::ALWAYS_ON
          when 'always_off' then Samplers::ALWAYS_OFF
          when 'traceidratio' then Samplers.trace_id_ratio_based(Float(ENV.fetch('OTEL_TRACES_SAMPLER_ARG', 1.0)))
          when 'parentbased_always_on' then Samplers.parent_based(root: Samplers::ALWAYS_ON)
          when 'parentbased_always_off' then Samplers.parent_based(root: Samplers::ALWAYS_OFF)
          when 'parentbased_traceidratio' then Samplers.parent_based(root: Samplers.trace_id_ratio_based(Float(ENV.fetch('OTEL_TRACES_SAMPLER_ARG', 1.0))))
          else default_sampler
          end
        rescue StandardError => e
          OpenTelemetry.handle_error(exception: e, message: "installing default sampler #{default_sampler.description}")
          default_sampler
        end
      end
    end
  end
end
