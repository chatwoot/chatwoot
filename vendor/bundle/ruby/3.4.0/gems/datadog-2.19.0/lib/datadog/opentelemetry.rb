# frozen_string_literal: true

# Entrypoint file for OpenTelemetry integration.
#
# This file's path is part of the @public_api.
#
# OpenTelemetry includes metrics, tracing, logs, and profiling.
# This file activates the integrations of all OpenTelemetry
# components supported by Datadog.

# Load Tracing
require_relative 'tracing'
require_relative 'tracing/contrib'

require_relative 'opentelemetry/api/context'
require_relative 'opentelemetry/api/baggage'

# DEV: Should this be a Contrib integration, that depends on the `opentelemetry-sdk`
# DEV: and checks for compatibility?
# DEV: This is different from our existing OpenTracer API, but there are many safety
# DEV: features built into Contrib instrumentation today.
require_relative 'opentelemetry/sdk/configurator' if defined?(OpenTelemetry::SDK)
require_relative 'opentelemetry/sdk/trace/span' if defined?(OpenTelemetry::SDK)

module Datadog
  # Datadog OpenTelemetry integration.
  module OpenTelemetry
    # Used by Telemetry to decide if OpenTelemetry instrumentation is enabled
    LOADED = true

    # Use `Datadog.logger` as the default logger
    def logger
      ::Datadog.logger
    end

    ::OpenTelemetry.singleton_class.prepend(self)
  end
end

# OpenTelemetry does not wait until the "root" span is finished to flush:
# the "root" span does not have special influence on flushing order.
#
# The "root" OpenTelemetry span might be a span that is never finished, but
# instead a placeholder for distributed tracing information, and ultimately gets discarded.
# Consumers of the OpenTelemetry SpanProcessor pipeline are free to flush spans whenever
# an individual span is finished.
# Currently, this closely translates to Datadog's partial flushing.
#
# @see OpenTelemetry::SDK::Trace::SpanProcessor#on_finish
Datadog.configure do |c|
  c.tracing.partial_flush.enabled = true
end
