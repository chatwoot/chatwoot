# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'logger'

require 'opentelemetry/error'
require 'opentelemetry/context'
require 'opentelemetry/baggage'
require 'opentelemetry/trace'
require 'opentelemetry/internal'
require 'opentelemetry/version'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
module OpenTelemetry
  extend self

  @mutex = Mutex.new
  @tracer_provider = Internal::ProxyTracerProvider.new

  attr_writer :propagation, :logger, :error_handler

  # @return [Object, Logger] configured Logger or a default STDOUT Logger.
  def logger
    @logger ||= Logger.new($stdout, level: ENV['OTEL_LOG_LEVEL'] || Logger::INFO)
  end

  # @return [Callable] configured error handler or a default that logs the
  #   exception and message at ERROR level.
  def error_handler
    @error_handler ||= ->(exception: nil, message: nil) { logger.error("OpenTelemetry error: #{[message, exception&.message, exception&.backtrace&.first].compact.join(' - ')}") }
  end

  # Handles an error by calling the configured error_handler.
  #
  # @param [optional Exception] exception The exception to be handled
  # @param [optional String] message An error message.
  def handle_error(exception: nil, message: nil)
    error_handler.call(exception: exception, message: message)
  end

  # Register the global tracer provider.
  #
  # @param [TracerProvider] provider A tracer provider to register as the
  #   global instance.
  def tracer_provider=(provider)
    @mutex.synchronize do
      if @tracer_provider.instance_of? Internal::ProxyTracerProvider
        logger.debug("Upgrading default proxy tracer provider to #{provider.class}")
        @tracer_provider.delegate = provider
      end
      @tracer_provider = provider
    end
  end

  # @return [Object, Trace::TracerProvider] registered tracer provider or a
  #   default no-op implementation of the tracer provider.
  def tracer_provider
    @mutex.synchronize { @tracer_provider }
  end

  # @return [Context::Propagation::Propagator] a propagator instance
  def propagation
    @propagation ||= Context::Propagation::NoopTextMapPropagator.new
  end
end
