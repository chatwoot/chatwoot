# frozen_string_literal: true

module SimpleCov
  # Functionally for combining coverage results
  #
  module Combine
  module_function

    #
    # Combine two coverage based on the given combiner_module.
    #
    # Combiners should always be called through this interface,
    # as it takes care of short-circuiting of one of the coverages is nil.
    #
    # @return [Hash]
    def combine(combiner_module, coverage_a, coverage_b)
      return existing_coverage(coverage_a, coverage_b) if empty_coverage?(coverage_a, coverage_b)

      combiner_module.combine(coverage_a, coverage_b)
    end

    def empty_coverage?(coverage_a, coverage_b)
      !(coverage_a && coverage_b)
    end

    def existing_coverage(coverage_a, coverage_b)
      coverage_a || coverage_b
    end
  end
end
