# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Internal
    # @api private
    #
    # {ProxyTracerProvider} is an implementation of {OpenTelemetry::Trace::TracerProvider}.
    # It is the default global tracer provider returned by OpenTelemetry.tracer_provider.
    # It delegates to a "real" TracerProvider after the global tracer provider is registered.
    # It returns {ProxyTracer} instances until the delegate is installed.
    class ProxyTracerProvider < Trace::TracerProvider
      Key = Struct.new(:name, :version)
      private_constant(:Key)

      # Returns a new {ProxyTracerProvider} instance.
      #
      # @return [ProxyTracerProvider]
      def initialize
        @mutex = Mutex.new
        @registry = {}
        @delegate = nil
      end

      # Set the delegate tracer provider. If this is called more than once, a warning will
      # be logged and superfluous calls will be ignored.
      #
      # @param [TracerProvider] provider The tracer provider to delegate to
      def delegate=(provider)
        unless @delegate.nil?
          OpenTelemetry.logger.warn 'Attempt to reset delegate in ProxyTracerProvider ignored.'
          return
        end

        @mutex.synchronize do
          @delegate = provider
          @registry.each { |key, tracer| tracer.delegate = provider.tracer(key.name, key.version) }
        end
      end

      # Returns a {Tracer} instance.
      #
      # @param [optional String] name Instrumentation package name
      # @param [optional String] version Instrumentation package version
      #
      # @return [Tracer]
      def tracer(name = nil, version = nil)
        @mutex.synchronize do
          return @delegate.tracer(name, version) unless @delegate.nil?

          @registry[Key.new(name, version)] ||= ProxyTracer.new
        end
      end
    end
  end
end
