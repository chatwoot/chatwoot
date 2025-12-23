# frozen_string_literal: true

require_relative 'sampler'

module Datadog
  module Tracing
    module Sampling
      # {Datadog::Tracing::Sampling::AllSampler} samples all the traces.
      class AllSampler < Sampler
        def sample?(_trace)
          true
        end

        def sample!(trace)
          trace.sampled = true
        end

        def sample_rate(*_)
          1.0
        end
      end
    end
  end
end
