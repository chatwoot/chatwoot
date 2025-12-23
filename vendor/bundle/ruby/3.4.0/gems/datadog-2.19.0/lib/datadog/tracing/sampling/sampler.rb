# frozen_string_literal: true

module Datadog
  module Tracing
    module Sampling
      # Interface for client-side trace sampling.
      # @abstract
      class Sampler
        # Returns `true` if the provided trace should be kept.
        # Otherwise, `false`.
        #
        # This method *may* modify the `trace`, in case changes are necessary based on the
        # sampling decision.
        #
        # @param [Datadog::Tracing::TraceOperation] trace
        # @return [Boolean] should this trace be kept?
        def sample!(trace)
          raise NotImplementedError, 'Samplers must implement the #sample! method'
        end

        # The sampling rate, if this sampler has such concept.
        # Otherwise, `nil`.
        #
        # @param [Datadog::Tracing::TraceOperation] trace
        # @return [Float,nil] sampling ratio between 0.0 and 1.0 (inclusive), or `nil` if not applicable
        def sample_rate(trace)
          raise NotImplementedError, 'Samplers must implement the #sample_rate method'
        end
      end
    end
  end
end
