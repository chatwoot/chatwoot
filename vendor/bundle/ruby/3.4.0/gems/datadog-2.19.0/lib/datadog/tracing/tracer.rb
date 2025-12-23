# frozen_string_literal: true

require_relative '../core/environment/ext'
require_relative '../core/environment/socket'

require_relative 'correlation'
require_relative 'event'
require_relative 'flush'
require_relative 'context_provider'
require_relative 'sampling/all_sampler'
require_relative 'sampling/rule_sampler'
require_relative 'sampling/priority_sampler'
require_relative 'sampling/span/sampler'
require_relative 'span_operation'
require_relative 'trace_digest'
require_relative 'trace_operation'
require_relative 'writer'

module Datadog
  module Tracing
    # A {Datadog::Tracing::Tracer} keeps track of the time spent by an application processing a single operation. For
    # example, a trace can be used to track the entire time spent processing a complicated web request.
    # Even though the request may require multiple resources and machines to handle the request, all
    # of these function calls and sub-requests would be encapsulated within a single trace.
    class Tracer
      attr_reader \
        :trace_flush,
        :provider,
        :sampler,
        :span_sampler,
        :tags,
        :logger

      attr_accessor \
        :default_service,
        :enabled,
        :writer

      # Initialize a new {Datadog::Tracing::Tracer} used to create, sample and submit spans that measure the
      # time of sections of code.
      #
      # @param trace_flush [Datadog::Tracing::TraceFlush] responsible for flushing spans from the execution context
      # @param context_provider [Datadog::Tracing::DefaultContextProvider] ensures different
      #                         execution contexts have distinct traces
      # @param default_service [String] A fallback value for {Datadog::Tracing::Span#service}, as spans without
      #                        service are rejected
      # @param enabled [Boolean] set if the tracer submits or not spans to the local agent
      # @param sampler [Datadog::Tracing::Sampler] a tracer sampler, responsible for filtering out spans when needed
      # @param tags [Hash] default tags added to all spans
      # @param writer [Datadog::Tracing::Writer] consumes traces returned by the provided +trace_flush+
      def initialize(
        # rubocop:disable Style/KeywordParametersOrder
        # https://github.com/rubocop/rubocop/issues/13933
        trace_flush: Flush::Finished.new,
        context_provider: DefaultContextProvider.new,
        default_service: Core::Environment::Ext::FALLBACK_SERVICE_NAME,
        enabled: true,
        logger: Datadog.logger,
        sampler: Sampling::PrioritySampler.new(
          base_sampler: Sampling::AllSampler.new,
          post_sampler: Sampling::RuleSampler.new
        ),
        span_sampler: Sampling::Span::Sampler.new,
        tags: {},
        # writer is not defaulted because creating it requires agent_settings,
        # which we do not have here and otherwise do not need.
        writer:
        # rubocop:enable Style/KeywordParametersOrder
      )
        @trace_flush = trace_flush
        @default_service = default_service
        @enabled = enabled
        @logger = logger
        @provider = context_provider
        @sampler = sampler
        @span_sampler = span_sampler
        @tags = tags
        @writer = writer
      end

      # Return a {Datadog::Tracing::SpanOperation span_op} and {Datadog::Tracing::TraceOperation trace_op}
      # that will trace an operation called `name`.
      #
      # You could trace your code using a <tt>do-block</tt> like:
      #
      # ```
      # tracer.trace('web.request') do |span_op, trace_op|
      #   span_op.service = 'my-web-site'
      #   span_op.resource = '/'
      #   span_op.set_tag('http.method', request.request_method)
      #   do_something()
      # end
      # ```
      #
      # The {#trace} method can also be used without a block in this way:
      # ```
      # span_op = tracer.trace('web.request', service: 'my-web-site')
      # do_something()
      # span_op.finish()
      # ```
      #
      # Remember that in this case, calling {Datadog::Tracing::SpanOperation#finish} is mandatory.
      #
      # When a Trace is started, {#trace} will store the created span; subsequent spans will
      # become its children and will inherit some properties:
      # ```
      # parent = tracer.trace('parent')   # has no parent span
      # child  = tracer.trace('child')    # is a child of 'parent'
      # child.finish()
      # parent.finish()
      # parent2 = tracer.trace('parent2') # has no parent span
      # parent2.finish()
      # ```
      #
      # @param [String] name {Datadog::Tracing::Span} operation name.
      #   See {https://docs.datadoghq.com/tracing/guide/configuring-primary-operation/ Primary Operations in Services}.
      # @param [Datadog::Tracing::TraceDigest] continue_from continue a trace from a {Datadog::Tracing::TraceDigest}.
      #   Used for linking traces that are executed asynchronously.
      # @param [Proc] on_error a block that overrides error handling behavior for this operation.
      # @param [String] resource the resource this span refers, or `name` if it's missing
      # @param [String] service the service name for this span.
      # @param [Time] start_time time which the span should have started.
      # @param [Hash<String,String>] tags extra tags which should be added to the span.
      # @param [String] type the type of the span. See {Datadog::Tracing::Metadata::Ext::AppTypes}.
      # @param [Integer] the id of the new span.
      # @return [Object] If a block is provided, returns the result of the block execution.
      # @return [Datadog::Tracing::SpanOperation] If no block is provided, returns the active,
      #         unfinished {Datadog::Tracing::SpanOperation}.
      # @yield Optional block where new newly created {Datadog::Tracing::SpanOperation} captures the execution.
      # @yieldparam [Datadog::Tracing::SpanOperation] span_op the newly created and active [Datadog::Tracing::SpanOperation]
      # @yieldparam [Datadog::Tracing::TraceOperation] trace_op the active [Datadog::Tracing::TraceOperation]
      # rubocop:disable Metrics/MethodLength
      def trace(
        name,
        continue_from: nil,
        on_error: nil,
        resource: nil,
        service: nil,
        start_time: nil,
        tags: nil,
        type: nil,
        id: nil,
        &block
      )
        return skip_trace(name, &block) unless enabled

        # Resolve the trace
        begin
          context = call_context
          active_trace = context.active_trace
          trace = if continue_from || active_trace.nil?
                    start_trace(continue_from: continue_from)
                  else
                    active_trace
                  end
        rescue StandardError => e
          logger.debug { "Failed to trace: #{e}" }

          # Tracing failed: fallback and run code without tracing.
          return skip_trace(name, &block)
        end

        # Activate and start the trace
        if block
          context.activate!(trace) do
            start_span(
              name,
              on_error: on_error,
              resource: resource,
              service: service,
              start_time: start_time,
              tags: tags,
              type: type,
              _trace: trace,
              id: id,
              &block
            )
          end
        else
          # Setup trace activation/deactivation
          manual_trace_activation!(context, trace)

          # Return the new span
          start_span(
            name,
            on_error: on_error,
            resource: resource,
            service: service,
            start_time: start_time,
            tags: tags,
            type: type,
            _trace: trace,
            id: id
          )
        end
      end
      # rubocop:enable Metrics/MethodLength

      # Set the given key / value tag pair at the tracer level. These tags will be
      # appended to each span created by the tracer. Keys and values must be strings.
      # @example
      #   tracer.set_tags('env' => 'prod', 'component' => 'core')
      def set_tags(tags)
        string_tags = tags.collect { |k, v| [k.to_s, v] }.to_h
        @tags = @tags.merge(string_tags)
      end

      # The active, unfinished trace, representing the current instrumentation context.
      #
      # The active trace is fiber-local.
      #
      # @param [Thread] key Thread to retrieve trace from. Defaults to current thread. For internal use only.
      # @return [Datadog::Tracing::TraceSegment] the active trace
      # @return [nil] if no trace is active
      def active_trace(key = nil)
        call_context(key).active_trace
      end

      # The active, unfinished span, representing the currently instrumented application section.
      #
      # The active span belongs to an {.active_trace}.
      #
      # @param [Thread] key Thread to retrieve trace from. Defaults to current thread. For internal use only.
      # @return [Datadog::Tracing::SpanOperation] the active span
      # @return [nil] if no trace is active, and thus no span is active
      def active_span(key = nil)
        trace = active_trace(key)
        trace.active_span if trace
      end

      # Information about the currently active trace.
      #
      # The most common use cases are tagging log messages and metrics.
      #
      # @param [Thread] key Thread to retrieve trace from. Defaults to current thread. For internal use only.
      # @return [Datadog::Tracing::Correlation::Identifier] correlation object
      def active_correlation(key = nil)
        trace = active_trace(key)

        return Datadog::Tracing::Correlation::Identifier.new unless trace

        trace.to_correlation
      end

      # Setup a new trace to continue from where another
      # trace left off.
      #
      # Used to continue distributed or async traces.
      #
      # @param [Datadog::Tracing::TraceDigest] digest continue from the {Datadog::Tracing::TraceDigest}.
      # @param [Thread] key Thread to retrieve trace from. Defaults to current thread. For internal use only.
      # @return [Object] If a block is provided, the result of the block execution.
      # @return [Datadog::Tracing::TraceOperation] If no block, the active {Datadog::Tracing::TraceOperation}.
      # @yield Optional block where this {#continue_trace!} `digest` scope is active.
      #   If no block, the `digest` remains active after {#continue_trace!} returns.
      def continue_trace!(digest, key = nil, &block)
        # Only accept {TraceDigest} as a digest.
        # Otherwise, create a new execution context.
        digest = nil unless digest.is_a?(TraceDigest)

        # Start a new trace from the digest
        context = call_context(key)
        original_trace = active_trace(key)
        trace = start_trace(continue_from: digest)

        # If block hasn't been given; we need to manually deactivate
        # this trace. Subscribe to the trace finished event to do this.
        subscribe_trace_deactivation!(context, trace, original_trace) unless block

        context.activate!(trace, &block)
      end

      # Sample a span, tagging the trace as appropriate.
      def sample_trace(trace_op)
        begin
          @sampler.sample!(trace_op) if trace_op.sampling_priority.nil?
        rescue StandardError => e
          SAMPLE_TRACE_LOG_ONLY_ONCE.run do
            logger.warn { "Failed to sample trace: #{e.class.name} #{e} at #{Array(e.backtrace).first}" }
          end
        end
      end

      # @!visibility private
      # TODO: make this private
      def trace_completed
        @trace_completed ||= TraceCompleted.new
      end

      # Triggered whenever a trace is completed
      class TraceCompleted < Tracing::Event
        def initialize
          super(:trace_completed)
        end

        # NOTE: Ignore Rubocop rule. This definition allows for
        #       description of and constraints on arguments.
        # rubocop:disable Lint/UselessMethodDefinition
        def publish(trace)
          super(trace)
        end
        # rubocop:enable Lint/UselessMethodDefinition
      end

      # Shorthand that calls the `shutdown!` method of a registered worker.
      # It's useful to ensure that the Trace Buffer is properly flushed before
      # shutting down the application.
      #
      # @example
      #   tracer.trace('operation_name', service='rake_tasks') do |span_op|
      #     span_op.set_tag('task.name', 'script')
      #   end
      #
      #   tracer.shutdown!
      def shutdown!
        return unless @enabled

        @writer.stop if @writer
      end

      private

      # Return the current active {Context} for this traced execution. This method is
      # automatically called when calling Tracer.trace or Tracer.start_span,
      # but it can be used in the application code during manual instrumentation.
      #
      # This method makes use of a {ContextProvider} that is automatically set during the tracer
      # initialization, or while using a library instrumentation.
      #
      # @param [Thread] key Thread to retrieve tracer from. Defaults to current thread.
      def call_context(key = nil)
        @provider.context(key)
      end

      def build_trace(digest = nil)
        # Resolve hostname if configured
        hostname = Core::Environment::Socket.hostname if Datadog.configuration.tracing.report_hostname
        hostname = hostname && !hostname.empty? ? hostname : nil

        if digest
          sampling_priority = if propagate_sampling_priority?(upstream_tags: digest.trace_distributed_tags)
                                digest.trace_sampling_priority
                              end
          TraceOperation.new(
            logger: logger,
            hostname: hostname,
            profiling_enabled: profiling_enabled,
            apm_tracing_enabled: apm_tracing_enabled,
            id: digest.trace_id,
            origin: digest.trace_origin,
            parent_span_id: digest.span_id,
            sampling_priority: sampling_priority,
            # Distributed tags are just regular trace tags with special meaning to Datadog
            tags: digest.trace_distributed_tags,
            trace_state: digest.trace_state,
            trace_state_unknown_fields: digest.trace_state_unknown_fields,
            remote_parent: digest.span_remote,
            tracer: self,
            baggage: digest.baggage
          )
        else
          TraceOperation.new(
            logger: logger,
            hostname: hostname,
            profiling_enabled: profiling_enabled,
            apm_tracing_enabled: apm_tracing_enabled,
            remote_parent: false,
            tracer: self
          )
        end
      end

      def bind_trace_events!(trace_op)
        events = trace_op.send(:events)

        events.span_before_start.subscribe do |event_span_op, event_trace_op|
          event_trace_op.service ||= @default_service
          event_span_op.service ||= @default_service
        end

        events.trace_propagated.subscribe do |event_trace_op|
          sample_trace(event_trace_op)
        end

        events.span_finished.subscribe do |event_span, event_trace_op|
          sample_trace(trace_op) if event_trace_op.sampling_priority.nil?
          sample_span(event_trace_op, event_span)
          flush_trace(event_trace_op)
        end
      end

      # Creates a new TraceOperation, with events bounds to this Tracer instance.
      # @return [TraceOperation]
      def start_trace(continue_from: nil)
        # Build a new trace using digest if provided.
        trace = build_trace(continue_from)

        # Bind trace events: sample trace, set default service, flush spans.
        bind_trace_events!(trace)

        trace
      end

      # rubocop:disable Lint/UnderscorePrefixedVariableName
      def start_span(
        name,
        continue_from: nil,
        on_error: nil,
        resource: nil,
        service: nil,
        start_time: nil,
        tags: nil,
        type: nil,
        _trace: nil,
        id: nil,
        &block
      )
        trace = _trace || start_trace(continue_from: continue_from)

        events = SpanOperation::Events.new(logger: logger)

        if block
          # Ignore start time if a block has been given
          trace.measure(
            name,
            logger: logger,
            events: events,
            on_error: on_error,
            resource: resource,
            service: service,
            tags: resolve_tags(tags, service),
            type: type,
            id: id,
            &block
          )
        else
          # Return the new span
          span = trace.build_span(
            name,
            logger: logger,
            events: events,
            on_error: on_error,
            resource: resource,
            service: service,
            start_time: start_time,
            tags: resolve_tags(tags, service),
            type: type,
            id: id
          )

          span.start(start_time)

          span
        end
      end
      # rubocop:enable Lint/UnderscorePrefixedVariableName

      def resolve_tags(tags, service)
        merged_tags = if @tags.any? && tags
                        # Combine default tags with provided tags,
                        # preferring provided tags.
                        @tags.merge(tags)
                      else
                        # Use provided tags or default tags if none.
                        tags || @tags.dup
                      end
        # Remove version tag if service is not the default service
        if merged_tags.key?(Core::Environment::Ext::TAG_VERSION) && service && service != @default_service
          merged_tags.delete(Core::Environment::Ext::TAG_VERSION)
        end
        merged_tags
      end

      # Manually activate and deactivate the trace, when the span completes.
      def manual_trace_activation!(context, trace)
        # Get the original trace to restore
        original_trace = context.active_trace

        # Setup the deactivation callback
        subscribe_trace_deactivation!(context, trace, original_trace)

        # Activate the trace
        # Skip this, if it would have no effect.
        context.activate!(trace) unless trace == original_trace
      end

      # Reactivate the original trace when trace completes
      def subscribe_trace_deactivation!(context, trace, original_trace)
        # Don't override this event if it's set.
        # The original event should reactivate the original trace correctly.
        #
        # This happens when multiple manually-activation spans are created:
        # ```ruby
        # tracer.trace('parent') do
        #   span1 = tracer.trace('first') # Registers trace deactivation back to `parent` span.
        #   span2 = tracer.trace('second') # Tries to register trace deactivation back to `first`, which is not correct.
        # end
        # ```
        return if trace.send(:events).trace_finished.deactivate_trace_subscribed?

        trace.send(:events).trace_finished.subscribe_deactivate_trace do
          context.activate!(original_trace)
        end
      end

      SAMPLE_TRACE_LOG_ONLY_ONCE = Core::Utils::OnlyOnce.new
      private_constant :SAMPLE_TRACE_LOG_ONLY_ONCE

      def sample_span(trace_op, span)
        begin
          @span_sampler.sample!(trace_op, span)
        rescue StandardError => e
          SAMPLE_SPAN_LOG_ONLY_ONCE.run do
            logger.warn { "Failed to sample span: #{e.class.name} #{e} at #{Array(e.backtrace).first}" }
          end
        end
      end

      SAMPLE_SPAN_LOG_ONLY_ONCE = Core::Utils::OnlyOnce.new
      private_constant :SAMPLE_SPAN_LOG_ONLY_ONCE

      # Flush finished spans from the trace buffer, send them to writer.
      def flush_trace(trace_op)
        begin
          trace = @trace_flush.consume!(trace_op)
          write(trace) if trace && !trace.empty?
        rescue StandardError => e
          FLUSH_TRACE_LOG_ONLY_ONCE.run do
            logger.warn { "Failed to flush trace: #{e.class.name} #{e} at #{Array(e.backtrace).first}" }
          end
        end
      end

      FLUSH_TRACE_LOG_ONLY_ONCE = Core::Utils::OnlyOnce.new
      private_constant :FLUSH_TRACE_LOG_ONLY_ONCE

      # Send the trace to the writer to enqueue the spans list in the agent
      # sending queue.
      def write(trace)
        return unless trace && @writer

        if Datadog.configuration.diagnostics.debug
          logger.debug { "Writing #{trace.length} spans (enabled: #{@enabled})\n#{trace.spans.pretty_inspect}" }
        end

        @writer.write(trace)
        trace_completed.publish(trace)
      end

      # TODO: Make these dummy objects singletons to preserve memory.
      def skip_trace(name)
        span = SpanOperation.new(name, logger: logger)

        if block_given?
          trace = TraceOperation.new(logger: logger)
          yield(span, trace)
        else
          span
        end
      end

      # Decide whether upstream sampling priority should be propagated, by taking into account
      # the upstream tags and the configuration.
      # We should always propagate if APM is enabled.
      #
      # e.g.: upstream tags containing dd.p.ts: 02, and appsec is enabled, return true.
      def propagate_sampling_priority?(upstream_tags:)
        return true if apm_tracing_enabled

        if upstream_tags&.key?(Tracing::Metadata::Ext::Distributed::TAG_TRACE_SOURCE)
          appsec_bit = upstream_tags[Tracing::Metadata::Ext::Distributed::TAG_TRACE_SOURCE].to_i(16) &
            Datadog::AppSec::Ext::PRODUCT_BIT
          return appsec_enabled if appsec_bit != 0
        end

        false
      end

      def profiling_enabled
        @profiling_enabled ||=
          !!(defined?(Datadog::Profiling) && Datadog::Profiling.respond_to?(:enabled?) && Datadog::Profiling.enabled?)
      end

      def appsec_enabled
        @appsec_enabled ||= Datadog.configuration.appsec.enabled
      end

      # Due to APM Tracing (the product) and Tracing (the transport) being intertwined, we cannot completely disabled APM
      # without also disabling the tracer. When setting `@apm_tracing_enabled` to `false`, it does not disable the tracer,
      # but rather only sends heartbeat traces (1 per minutes), so that the service is considered alive in the backend.
      # Other products (like ASM) can then set the sampling priority of their traces to `MANUAL_KEEP`,
      # effectively allowing standalone products to work without APM.
      def apm_tracing_enabled
        @apm_tracing_enabled ||= Datadog.configuration.apm.tracing.enabled
      end
    end
  end
end
