# frozen_string_literal: true

require_relative 'span_processor'
require_relative 'id_generator'
require_relative 'propagator'

module Datadog
  module OpenTelemetry
    module SDK
      # The Configurator is responsible for setting wiring up
      # different OpenTelemetry requirements together.
      # Some of the requirements will be changed to Datadog versions.
      module Configurator
        def initialize
          super
          @id_generator = IdGenerator
        end

        # Ensure Datadog-configure propagation styles have are applied when configured.
        #
        # DEV: Support configuring propagation through the environment variable
        # DEV: `OTEL_PROPAGATORS`, similar to `DD_TRACE_PROPAGATION*`?
        def configure_propagation
          @propagators = [Propagator.new(Tracing::Contrib::HTTP)]
          super
        end

        # Ensure Datadog-configure trace writer is configured.
        def wrapped_exporters_from_env
          [SpanProcessor.new]
        end

        ::OpenTelemetry::SDK::Configurator.prepend(self)
      end
    end
  end
end
