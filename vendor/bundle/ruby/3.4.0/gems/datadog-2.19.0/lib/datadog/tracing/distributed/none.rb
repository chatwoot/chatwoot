# frozen_string_literal: true

module Datadog
  module Tracing
    module Distributed
      # Propagator that does not inject nor extract data. It performs no operation.
      # Supported for feature parity with OpenTelemetry.
      # @see https://github.com/open-telemetry/opentelemetry-specification/blob/255a6c52b8914a2ed7e26bb5585abecab276aafc/specification/sdk-environment-variables.md?plain=1#L88
      class None
        # No-op
        def inject!(_digest, _data); end

        # No-op
        def extract(_data); end
      end
    end
  end
end
