# frozen_string_literal: true

require_relative 'trace/span'
require_relative '../../tracing/trace_operation'
require_relative '../trace'

module Datadog
  module OpenTelemetry
    module API
      # The OpenTelemetry Context contains a key-value store that can be attached
      # to a trace.
      #
      # It loosely matches our `TraceOperations#tags`, except for the following:
      # * Context can store arbitrary objects as values. One example is for the key
      #   `Context::Key.new('current-span')`, which is associated with a `Span` object.
      #   In contrast, `TraceOperations#tags` only stores string values.
      # * Context is how spans know who their parent span is. The parenting operation happens on every
      #   span created. Parenting is not directly tied to the active Fiber or Thread.
      # * Context is immutable: changing a value creates a copy of Context.
      # * Context is not bound to a specific trace: it can be reused an arbitrary number of times.
      module Context
        CURRENT_SPAN_KEY = ::OpenTelemetry::Trace.const_get(:CURRENT_SPAN_KEY)
        private_constant :CURRENT_SPAN_KEY
        BAGGAGE_REMOVE_KEY = Object.new # sentinel object to indicate the deletion of a value in baggage

        def initialize(entries, trace: nil, baggage: nil)
          @trace = trace || ::Datadog::Tracing.send(:tracer).send(:start_trace)
          @trace.otel_values.merge!(entries) if entries
          @trace.otel_context ||= self
          @trace.baggage = baggage if baggage
        end

        # Because Context can be reused, we have to make sure we have
        # a valid `TraceOperation` on every invocation.
        def ensure_trace
          return nil unless @trace

          # The Context can be reused after the root span has finished.
          @trace.send(:reset) if @trace.finished?
          @trace
        end

        # Returns the corresponding value (or nil) for key
        #
        # @param [Key] key The lookup key
        # @return [Object]
        def value(key)
          return nil unless @trace

          @trace.otel_value(key)
        end

        alias [] value

        # Returns a new Context where entries contains the newly added key and value
        #
        # @param [Key] key The key to store this value under
        # @param [Object] value Object to be stored under key
        # @return [Context]
        def set_value(key, value)
          set_values(key => value)
        end

        # Returns a new Context with the current context's entries merged with the
        #   new entries
        #
        # @param [Hash] values The values to be merged with the current context's
        #   entries.
        # @param [Object] value Object to be stored under key
        # @return [Context]
        def set_values(values)
          if (current_span = values[CURRENT_SPAN_KEY]) && current_span.datadog_trace
            # Because `#set_value` returns new context, we have to create
            # a new copy of the active trace to ensure there's no conflict with
            # other users of the active trace.
            # It effectively becomes an internal trace propagation.
            trace = Datadog::OpenTelemetry::Trace.start_trace_copy(
              current_span.datadog_trace,
              parent_span: current_span.datadog_span
            )
          end

          existing_values = @trace && @trace.otel_values || {}
          existing_baggage = @trace && @trace.baggage || {}

          # Retrieve the baggage removal sentinel and remove it from the values hash
          existing_baggage.delete(values[BAGGAGE_REMOVE_KEY]) if values.key?(BAGGAGE_REMOVE_KEY)

          # If the values hash contains a BAGGAGE_KEY, merge its contents with existing baggage
          # Otherwise, keep the existing baggage unchanged
          new_baggage = if values.key?(::OpenTelemetry::Baggage.const_get(:BAGGAGE_KEY))
                          existing_baggage.merge(values[::OpenTelemetry::Baggage.const_get(:BAGGAGE_KEY)])
                        else
                          existing_baggage
                        end

          ::OpenTelemetry::Context.new(existing_values.merge(values), trace: trace, baggage: new_baggage)
        end

        # The Datadog {TraceOperation} associated with this {Context}.
        def trace
          @trace
        end

        # Singleton class methods for {Context}
        module SingletonClass
          # Returns current context, which is never nil
          #
          # @return [Context]
          def current
            trace = Tracing.active_trace
            return ::OpenTelemetry::Context::ROOT unless trace

            trace.otel_context ||= ::OpenTelemetry::Context.from_trace(trace)
          end

          # Associates a Context with the caller's current Fiber. Every call to
          # this operation should be paired with a corresponding call to detach.
          #
          # Returns a token to be used with the matching call to detach
          #
          # @param [Context] context The new context
          # @return [Object] A token to be used when detaching
          def attach(context)
            previous_trace = Tracing.active_trace
            continue_trace!(context)

            stack.push(previous_trace && previous_trace.otel_context || ::OpenTelemetry::Context::ROOT)
            stack.size
          end

          # Restores the previous Context associated with the current Fiber.
          # The supplied token is used to check if the call to detach is balanced
          # with a corresponding attach call. A warning is logged if the
          # calls are unbalanced.
          #
          # @param [Object] token The token provided by the matching call to attach
          # @return [Boolean] True if the calls matched, false otherwise
          def detach(token)
            s = stack
            calls_matched = (token == s.size)
            unless calls_matched
              ::OpenTelemetry.handle_error(
                exception: ::OpenTelemetry::Context::DetachError.new(
                  'calls to detach should match corresponding calls to attach.'
                )
              )
            end

            previous_context = s.pop
            continue_trace!(previous_context)
            calls_matched
          end

          # Part of the OpenTelemetry public API for {Context}.
          def clear
            super
            tracer = Tracing.send(:tracer)
            tracer.send(:call_context).activate!(nil)
          end

          # Creates a new {Context} associated with a {TraceOperation}.
          def from_trace(trace)
            new({}, trace: trace)
          end

          private

          def continue_trace!(context, &block)
            call_context = Tracing.send(:tracer).send(:call_context)
            if context && context.trace
              call_context.activate!(context.ensure_trace, &block)
            else
              call_context.activate!(nil)
            end
          end
        end

        def self.prepended(base)
          base.singleton_class.prepend(SingletonClass)
        end

        ::OpenTelemetry::Context.prepend(self)
      end

      # OpenTelemetry-specific {TraceOperation} features.
      #
      # These extensions providing matching between {TraceOperation}
      # and OpenTelemetry {Context}.
      module TraceOperation
        attr_accessor :otel_context

        # Stores values from Context#entries
        def otel_value(key)
          otel_values[key]
        end

        # Retrieves values for Context#entries
        def otel_values
          @otel_values ||= {}
        end

        Tracing::TraceOperation.include(self)
      end
    end
  end
end
