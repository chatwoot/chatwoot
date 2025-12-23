# frozen_string_literal: true

require_relative 'trace/span'
require_relative '../../tracing/trace_operation'
require_relative '../trace'

module Datadog
  module OpenTelemetry
    module API
      # The Baggage module provides an implementation of the OpenTelemetry Baggage API.
      #
      # Baggage is a set of name/value pairs describing user-defined properties that can be
      # propagated through a distributed trace. This implementation follows the W3C Baggage
      # specification and the OpenTelemetry Baggage API.
      #
      # @see https://www.w3.org/TR/baggage/
      # @see https://opentelemetry.io/docs/specs/otel/baggage/api/
      module Baggage
        def initialize(trace: nil)
          @trace = trace
        end

        # Returns a new context with empty baggage
        #
        # @param [optional Context] context Context to clear baggage from. Defaults
        # to ::OpenTelemetry::Context.current
        # @return [Context]
        def clear(context: ::OpenTelemetry::Context.current)
          context.ensure_trace.baggage.clear
          context
        end

        # Returns the corresponding value for key
        #
        # @param [String] key The lookup key
        # @param [optional Context] context The context from which to retrieve
        # the key. Defaults to ::OpenTelemetry::Context.current
        # @return [String, nil]
        def value(key, context: ::OpenTelemetry::Context.current)
          trace = context.ensure_trace
          return nil if trace.nil?

          trace.baggage && trace.baggage[key]
        end

        # Returns all baggage values
        #
        # @param [optional Context] context The context from which to retrieve
        # the baggage. Defaults to ::OpenTelemetry::Context.current
        # @return [Hash<String, String>]
        def values(context: ::OpenTelemetry::Context.current)
          trace = context.ensure_trace
          return {} if trace.nil?

          trace.baggage ? trace.baggage.dup : {}
        end

        # Returns a new context with new key-value pair
        #
        # @param [String] key The key to store this value under
        # @param [String] value String value to be stored under key
        # @param [optional String] metadata This is here to store properties
        # received from other W3C Baggage implementations but is not exposed in
        # OpenTelemetry. This is considered private API and not for use by
        # end-users.
        # @param [optional Context] context The context to update with new
        # value. Defaults to ::OpenTelemetry::Context.current
        # @return [Context]
        def set_value(key, value, metadata: nil, context: ::OpenTelemetry::Context.current)
          # Delegate to the context to set the value because an active trace is not guaranteed
          # set_values handles this logic
          context.set_values({ ::OpenTelemetry::Baggage.const_get(:BAGGAGE_KEY) => { key => value } })
        end

        # Returns a new context with value at key removed
        #
        # @param [String] key The key to remove
        # @param [optional Context] context The context to remove baggage
        # from. Defaults to ::OpenTelemetry::Context.current
        # @return [Context]
        def remove_value(key, context: ::OpenTelemetry::Context.current)
          # Delegate to the context to remove the value because an active trace is not guaranteed
          # set_values handles this logic
          context.set_values({ Context::BAGGAGE_REMOVE_KEY => key })
        end
        ::OpenTelemetry::Baggage.singleton_class.prepend(self)
      end
    end
  end
end
