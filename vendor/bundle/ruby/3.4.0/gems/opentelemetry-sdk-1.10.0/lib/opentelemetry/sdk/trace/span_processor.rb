# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module SDK
    module Trace
      # SpanProcessor describes a duck type and provides synchronous no-op hooks for when a
      # {Span} is started or when a {Span} is ended. It is not required to subclass this
      # class to provide an implementation of SpanProcessor, provided the interface is
      # satisfied.
      class SpanProcessor
        # Called when a {Span} is started, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just started.
        # @param [Context] parent_context the parent {Context} of the newly
        #  started span.
        def on_start(span, parent_context); end

        # The on_finishing method is an experimental feature and may have breaking changes.
        # The OpenTelemetry specification defines it as "On Ending". As `end` is a reserved
        # keyword in Ruby, we are using `on_finishing` instead.
        #
        # Called when a {Span} is ending, after the end timestamp has been set
        # but before span becomes immutable. This allows for updating the span
        # by setting attributes or adding links and events.
        #
        # This method is called synchronously and should not block the current
        # thread nor throw exceptions.
        #
        # This method is optional on the Span Processor interface. It will only
        # get called if it exists within the processor.
        #
        # @param [Span] span the {Span} that just is ending (still mutable).
        # @return [void]
        def on_finishing(span); end

        # Called when a {Span} is ended, if the {Span#recording?}
        # returns true.
        #
        # This method is called synchronously on the execution thread, should
        # not throw or block the execution thread.
        #
        # @param [Span] span the {Span} that just ended.
        def on_finish(span); end

        # Export all ended spans to the configured `Exporter` that have not yet
        # been exported.
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
          Export::SUCCESS
        end

        # Called when {TracerProvider#shutdown} is called.
        #
        # @param [optional Numeric] timeout An optional timeout in seconds.
        # @return [Integer] Export::SUCCESS if no error occurred, Export::FAILURE if
        #   a non-specific failure occurred, Export::TIMEOUT if a timeout occurred.
        def shutdown(timeout: nil)
          Export::SUCCESS
        end
      end
    end
  end
end
