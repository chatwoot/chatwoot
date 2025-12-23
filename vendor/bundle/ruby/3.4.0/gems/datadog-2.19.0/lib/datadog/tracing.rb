# frozen_string_literal: true

require_relative 'core'
require_relative 'tracing/pipeline'

module Datadog
  # Datadog APM tracing public API.
  #
  # The Datadog team ensures that public methods in this module
  # only receive backwards compatible changes, and breaking changes
  # will only occur in new major versions releases.
  # @public_api
  module Tracing
    class << self
      # (see Datadog::Tracing::Tracer#trace)
      # @public_api
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
        tracer.trace(
          name,
          continue_from: continue_from,
          on_error: on_error,
          resource: resource,
          service: service,
          start_time: start_time,
          tags: tags,
          type: type,
          id: id,
          &block
        )
      end

      # (see Datadog::Tracing::Tracer#continue_trace!)
      # @public_api
      def continue_trace!(digest, &block)
        tracer.continue_trace!(digest, &block)
      end

      # The tracer's internal logger instance.
      # All tracing log output is handled by this object.
      #
      # The logger can be configured through {.configure},
      # through {Datadog::Core::Configuration::Settings::DSL::Logger} options.
      #
      # @!attribute [r] logger
      # @public_api
      def logger
        Datadog.logger
      end

      # (see Datadog::Tracing::Tracer#active_trace)
      # @public_api
      def active_trace
        current_tracer = tracer
        return unless current_tracer

        current_tracer.active_trace
      end

      # (see Datadog::Tracing::Tracer#active_span)
      # @public_api
      def active_span
        current_tracer = tracer
        return unless current_tracer

        current_tracer.active_span
      end

      # (see Datadog::Tracing::TraceSegment#keep!)
      # If no trace is active, no action is taken.
      # @public_api
      def keep!
        trace = active_trace
        trace.keep! if trace
      end

      # (see Datadog::Tracing::TraceSegment#reject!)
      # If no trace is active, no action is taken.
      # @public_api
      def reject!
        trace = active_trace
        trace.reject! if trace
      end

      # (see Datadog::Tracing::Tracer#active_correlation)
      # @public_api
      def correlation
        # We access this in this way as:
        # * If the components have not been initialized, it doesn't make sense to initialize datadog just to say
        #   'nil' here
        # * It prevents recursive initialization attempts, see https://github.com/DataDog/dd-trace-rb/issues/3385
        components = Datadog.send(:components, allow_initialization: false)
        current_tracer = components.tracer if components

        return Datadog::Tracing::Correlation::Identifier.new unless current_tracer

        current_tracer.active_correlation
      end

      # Textual representation of {.correlation}, which can be
      # added to individual log lines in order to correlate them with the active
      # trace.
      #
      # Example:
      #
      # ```
      # MyLogger.log("#{Datadog::Tracing.log_correlation}] My message")
      # # dd.env=prod dd.service=auth dd.version=13.8 dd.trace_id=5458478252992251 dd.span_id=7117552347370098 My message
      # ```
      #
      # @return [String] correlation information; or an empty String if Tracing is disabled (`!enabled?`)
      # @public_api
      def log_correlation
        return '' unless enabled?

        correlation.to_log_format
      end

      # Returns the baggage for the current trace.
      #
      # If there is no active trace, a new one is created.
      #
      # @return [Datadog::Tracing::Distributed::Baggage] The baggage for the current trace.
      # @public_api
      def baggage
        # Baggage should not be dependent on there being an active trace.
        # So we create a new TraceOperation if there isn't one.
        active_trace = self.active_trace || tracer.continue_trace!(nil)
        active_trace.baggage ||= {}
        active_trace.baggage
      end

      # Gracefully shuts down the tracer.
      #
      # The public tracing API will still respond to method calls as usual
      # but might not internally perform the expected internal work after shutdown.
      #
      # This avoids errors being raised across the host application
      # during shutdown while allowing for the graceful decommission of resources.
      #
      # {.shutdown!} cannot be reversed.
      # @public_api
      def shutdown!
        current_tracer = tracer
        return unless current_tracer

        current_tracer.shutdown!
      end

      # (see Datadog::Tracing::Pipeline.before_flush)
      def before_flush(*processors, &processor_block)
        Pipeline.before_flush(*processors, &processor_block)
      end

      # Is the tracer collecting telemetry data in this process?
      # @return [Boolean] `true` if the tracer is collecting data in this process, otherwise `false`.
      def enabled?
        current_tracer = tracer
        return false unless current_tracer

        current_tracer.enabled
      end

      private

      # DEV: components hosts both tracing and profiling inner objects today
      def components
        Datadog.send(:components)
      end

      def tracer
        components.tracer
      end
    end
  end
end
