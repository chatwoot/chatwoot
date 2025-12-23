# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry'
require 'opentelemetry/common'
require 'opentelemetry-registry'
require 'opentelemetry-semantic_conventions'

# OpenTelemetry is an open source observability framework, providing a
# general-purpose API, SDK, and related tools required for the instrumentation
# of cloud-native software, frameworks, and libraries.
#
# The OpenTelemetry module provides global accessors for telemetry objects.
# See the documentation for the `opentelemetry-api` gem for details.
module OpenTelemetry
  # SDK provides the reference implementation of the OpenTelemetry API.
  module SDK
    extend self

    # ConfigurationError is an exception type used to wrap configuration errors
    # passed to OpenTelemetry.error_handler. This can be used to distinguish
    # errors reported during SDK configuration.
    ConfigurationError = Class.new(OpenTelemetry::Error)

    # Configures SDK and instrumentation
    #
    # @yieldparam [Configurator] configurator Yields a configurator to the
    #   provided block
    #
    # Example usage:
    #   Without a block defaults are installed without any instrumentation
    #
    #     OpenTelemetry::SDK.configure
    #
    #   Install instrumentation individually with optional config
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.use 'OpenTelemetry::Instrumentation::Faraday', tracer_middleware: SomeMiddleware
    #     end
    #
    #   Install all instrumentation with optional config
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.use_all 'OpenTelemetry::Instrumentation::Faraday' => { tracer_middleware: SomeMiddleware }
    #     end
    #
    #   Add a span processor
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.add_span_processor SpanProcessor.new(SomeExporter.new)
    #     end
    #
    #   Configure everything
    #
    #     OpenTelemetry::SDK.configure do |c|
    #       c.logger = Logger.new(File::NULL)
    #       c.add_span_processor SpanProcessor.new(SomeExporter.new)
    #       c.use_all
    #     end
    def configure
      if ENV['OTEL_SDK_DISABLED'] == 'true'
        OpenTelemetry.logger.warn 'Environment variable OTEL_SDK_DISABLED is defined as true. SDK is disabled.'
        return
      end

      configurator = Configurator.new
      yield configurator if block_given?
      configurator.configure
    rescue StandardError
      begin
        raise ConfigurationError
      rescue ConfigurationError => e
        OpenTelemetry.handle_error(exception: e, message: "unexpected configuration error due to #{e.cause}")
      end
    end
  end
end

require 'opentelemetry/sdk/configurator'
require 'opentelemetry/sdk/forwarding_logger'
require 'opentelemetry/sdk/internal'
require 'opentelemetry/sdk/instrumentation_library'
require 'opentelemetry/sdk/instrumentation_scope'
require 'opentelemetry/sdk/resources'
require 'opentelemetry/sdk/trace'
require 'opentelemetry/sdk/version'
