# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      module Export
        # An implementation of the duck type SpanProcessor that converts the
        # {Span} to {io.opentelemetry.proto.trace.v1.Span} and passes it to the
        # configured exporter.
        #
        # Typically, the SimpleSpanProcessor will be most suitable for use in testing;
        # it should be used with caution in production. It may be appropriate for
        # production use in scenarios where creating multiple threads is not desirable
        # as well as scenarios where different custom attributes should be added to
        # individual spans based on code scopes.
        #
        # Only spans that are recorded are converted, {OpenTelemetry::Trace::Span#is_recording?} must
        # return true.
        class SimpleSpanProcessor
          # Returns a new {SimpleSpanProcessor} that converts spans to
          # proto and forwards them to the given span_exporter.
          #
          # @param span_exporter the (duck type) SpanExporter to where the
          #   recorded Spans are pushed.
          # @return [SimpleSpanProcessor]
          # @raise ArgumentError if the span_exporter is nil.
          def initialize(span_exporter)
            raise ArgumentError, "exporter #{span_exporter.inspect} does not appear to be a valid exporter" unless Common::Utilities.valid_exporter?(span_exporter)

            @span_exporter = span_exporter
          end

          # Called when a {Span} is started, if the {Span#recording?}
          # returns true.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [Span] span the {Span} that just started.
          # @param [Context] parent_context the parent {Context} of the newly
          #  started span.
          def on_start(span, parent_context)
            # Do nothing.
          end

          # Called when a {Span} is ended, if the {Span#recording?}
          # returns true.
          #
          # This method is called synchronously on the execution thread, should
          # not throw or block the execution thread.
          #
          # @param [Span] span the {Span} that just ended.
          def on_finish(span)
            return unless span.context.trace_flags.sampled?

            @span_exporter&.export([span.to_span_data])
          rescue => e # rubocop:disable Style/RescueStandardError
            OpenTelemetry.handle_error(exception: e, message: 'unexpected error in span.on_finish')
          end

          # Export all ended spans to the configured `Exporter` that have not yet
          # been exported, then call {Exporter#force_flush}.
          #
          # This method should only be called in cases where it is absolutely
          # necessary, such as when using some FaaS providers that may suspend
          # the process after an invocation, but before the `Processor` exports
          # the completed spans.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def force_flush(timeout: nil)
            @span_exporter&.force_flush(timeout: timeout) || SUCCESS
          end

          # Called when {TracerProvider#shutdown} is called.
          #
          # @param [optional Numeric] timeout An optional timeout in seconds.
          # @return [Integer] SUCCESS if no error occurred, FAILURE if a
          #   non-specific failure occurred, TIMEOUT if a timeout occurred.
          def shutdown(timeout: nil)
            @span_exporter&.shutdown(timeout: timeout) || SUCCESS
          end
        end
      end
    end
  end
end
