# frozen_string_literal: true

module Datadog
  module Tracing
    module Sampling
      module Span
        # Single Span Sampling constants.
        module Ext
          # Accept all spans (100% retention).
          DEFAULT_SAMPLE_RATE = 1.0
          # Unlimited.
          # @see Datadog::Core::TokenBucket
          DEFAULT_MAX_PER_SECOND = -1

          # Sampling decision method used to come to the sampling decision for this span
          TAG_MECHANISM = '_dd.span_sampling.mechanism'
          # Sampling rate applied to this span, if a rule applies
          TAG_RULE_RATE = '_dd.span_sampling.rule_rate'
          # Rate limit configured for this span, if a rule applies
          TAG_MAX_PER_SECOND = '_dd.span_sampling.max_per_second'
        end
      end
    end
  end
end
