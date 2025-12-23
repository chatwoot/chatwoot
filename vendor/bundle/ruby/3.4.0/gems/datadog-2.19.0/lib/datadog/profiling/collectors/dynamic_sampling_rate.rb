# frozen_string_literal: true

module Datadog
  module Profiling
    module Collectors
      # Used to pace the rate of profiling samples based on the last observed time for a sample.
      # All of this module is implemented as native code.
      #
      # Methods prefixed with _native_ are implemented in `collectors_dynamic_sampling_rate.c`
      module DynamicSamplingRate
      end
    end
  end
end
