# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry/context/key'
require 'opentelemetry/context/propagation'

module OpenTelemetry # rubocop:disable Style/Documentation
  Fiber.attr_accessor :opentelemetry_context

  # Manages context on a per-fiber basis
  class Context
    EMPTY_ENTRIES = {}.freeze
    private_constant :EMPTY_ENTRIES

    DetachError = Class.new(OpenTelemetry::Error)

    class << self
      # Returns a key used to index a value in a Context
      #
      # @param [String] name The key name
      # @return [Context::Key]
      def create_key(name)
        Key.new(name)
      end

      # Returns current context, which is never nil
      #
      # @return [Context]
      def current
        stack.last || ROOT
      end

      # Associates a Context with the caller's current Fiber. Every call to
      # this operation should be paired with a corresponding call to detach.
      #
      # Returns a token to be used with the matching call to detach
      #
      # @param [Context] context The new context
      # @return [Object] A token to be used when detaching
      def attach(context)
        s = stack
        s.push(context)
        s.size
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
        OpenTelemetry.handle_error(exception: DetachError.new('calls to detach should match corresponding calls to attach.')) unless calls_matched

        s.pop
        calls_matched
      end

      # Executes a block with ctx as the current context. It restores
      # the previous context upon exiting.
      #
      # @param [Context] ctx The context to be made active
      # @yield [context] Yields context to the block
      def with_current(ctx)
        token = attach(ctx)
        yield ctx
      ensure
        detach(token)
      end

      # Execute a block in a new context with key set to value. Restores the
      # previous context after the block executes.

      # @param [String] key The lookup key
      # @param [Object] value The object stored under key
      # @param [Callable] Block to execute in a new context
      # @yield [context, value] Yields the newly created context and value to
      #   the block
      def with_value(key, value)
        ctx = current.set_value(key, value)
        token = attach(ctx)
        yield ctx, value
      ensure
        detach(token)
      end

      # Execute a block in a new context where its values are merged with the
      # incoming values. Restores the previous context after the block executes.

      # @param [String] key The lookup key
      # @param [Hash] values Will be merged with values of the current context
      #  and returned in a new context
      # @param [Callable] Block to execute in a new context
      # @yield [context, values] Yields the newly created context and values
      #   to the block
      def with_values(values)
        ctx = current.set_values(values)
        token = attach(ctx)
        yield ctx, values
      ensure
        detach(token)
      end

      # Returns the value associated with key in the current context
      #
      # @param [String] key The lookup key
      def value(key)
        current.value(key)
      end

      # Clears the fiber-local Context stack.
      def clear
        Fiber.current.opentelemetry_context = []
      end

      def empty
        new(EMPTY_ENTRIES)
      end

      private

      def stack
        Fiber.current.opentelemetry_context ||= []
      end
    end

    def initialize(entries)
      @entries = entries.freeze
    end

    # Returns the corresponding value (or nil) for key
    #
    # @param [Key] key The lookup key
    # @return [Object]
    def value(key)
      @entries[key]
    end

    alias [] value

    # Returns a new Context where entries contains the newly added key and value
    #
    # @param [Key] key The key to store this value under
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_value(key, value)
      new_entries = @entries.dup
      new_entries[key] = value
      Context.new(new_entries)
    end

    # Returns a new Context with the current context's entries merged with the
    #   new entries
    #
    # @param [Hash] values The values to be merged with the current context's
    #   entries.
    # @param [Object] value Object to be stored under key
    # @return [Context]
    def set_values(values) # rubocop:disable Naming/AccessorMethodName:
      Context.new(@entries.merge(values))
    end

    ROOT = empty.freeze
  end
end
