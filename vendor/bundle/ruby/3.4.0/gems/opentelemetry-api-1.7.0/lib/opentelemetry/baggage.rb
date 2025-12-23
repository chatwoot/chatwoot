# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/baggage/propagation'
require 'opentelemetry/baggage/builder'
require 'opentelemetry/baggage/entry'

module OpenTelemetry
  # The Baggage module provides functionality to record and propagate
  # baggage in a distributed trace
  module Baggage
    extend self

    BAGGAGE_KEY = OpenTelemetry::Baggage::Propagation::ContextKeys.baggage_key
    EMPTY_BAGGAGE = {}.freeze
    private_constant(:BAGGAGE_KEY, :EMPTY_BAGGAGE)

    # Used to chain modifications to baggage. The result is a
    # context with an updated baggage. If only a single
    # modification is being made to baggage, use the other
    # methods on +Baggage+, if multiple modifications are being made, use
    # this one.
    #
    # @param [optional Context] context The context to update with with new
    #   modified baggage. Defaults to +Context.current+
    # @return [Context]
    def build(context: Context.current)
      builder = Builder.new(baggage_for(context).dup)
      yield builder
      context.set_value(BAGGAGE_KEY, builder.entries)
    end

    # Returns a new context with empty baggage
    #
    # @param [optional Context] context Context to clear baggage from. Defaults
    #   to +Context.current+
    # @return [Context]
    def clear(context: Context.current)
      context.set_value(BAGGAGE_KEY, EMPTY_BAGGAGE)
    end

    # Returns the corresponding baggage.entry (or nil) for key
    #
    # @param [String] key The lookup key
    # @param [optional Context] context The context from which to retrieve
    #   the key.
    #   Defaults to +Context.current+
    # @return [String]
    def value(key, context: Context.current)
      baggage_for(context)[key]&.value
    end

    # Returns the baggage
    #
    # @param [optional Context] context The context from which to retrieve
    #   the baggage.
    #   Defaults to +Context.current+
    # @return [Hash]
    def values(context: Context.current)
      baggage_for(context).transform_values(&:value)
    end

    # @api private
    def raw_entries(context: Context.current)
      baggage_for(context).dup.freeze
    end

    # Returns a new context with new key-value pair
    #
    # @param [String] key The key to store this value under
    # @param [String] value String value to be stored under key
    # @param [optional String] metadata This is here to store properties
    #   received from other W3C Baggage implementations but is not exposed in
    #   OpenTelemetry. This is condsidered private API and not for use by
    #   end-users.
    # @param [optional Context] context The context to update with new
    #   value. Defaults to +Context.current+
    # @return [Context]
    def set_value(key, value, metadata: nil, context: Context.current)
      new_baggage = baggage_for(context).dup
      new_baggage[key] = Entry.new(value, metadata)
      context.set_value(BAGGAGE_KEY, new_baggage)
    end

    # Returns a new context with value at key removed
    #
    # @param [String] key The key to remove
    # @param [optional Context] context The context to remove baggage
    #   from. Defaults to +Context.current+
    # @return [Context]
    def remove_value(key, context: Context.current)
      baggage = baggage_for(context)
      return context unless baggage.key?(key)

      new_baggage = baggage.dup
      new_baggage.delete(key)
      context.set_value(BAGGAGE_KEY, new_baggage)
    end

    private

    def baggage_for(context)
      context.value(BAGGAGE_KEY) || EMPTY_BAGGAGE
    end
  end
end
