# frozen_string_literal: true

module Datadog
  module OpenTelemetry
    module Trace
      # Stores associated Datadog entities to the OpenTelemetry Span.
      module Span
        attr_accessor :datadog_trace, :datadog_span

        ::OpenTelemetry::Trace::Span.prepend(self)
      end
    end
  end
end
