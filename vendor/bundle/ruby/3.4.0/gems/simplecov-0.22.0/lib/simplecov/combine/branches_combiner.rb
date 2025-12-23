# frozen_string_literal: true

module SimpleCov
  module Combine
    #
    # Combine different branch coverage results on single file.
    #
    # Should be called through `SimpleCov.combine`.
    module BranchesCombiner
    module_function

      #
      # Return merged branches or the existed brach if other is missing.
      #
      # Branches inside files are always same if they exist, the difference only in coverage count.
      # Branch coverage report for any conditional case is built from hash, it's key is a condition and
      # it's body is a hash << keys from condition and value is coverage rate >>.
      # ex: branches =>{ [:if, 3, 8, 6, 8, 36] => {[:then, 4, 8, 6, 8, 12] => 1, [:else, 5, 8, 6, 8, 36]=>2}, other conditions...}
      # We create copy of result and update it values depending on the combined branches coverage values.
      #
      # @return [Hash]
      #
      def combine(coverage_a, coverage_b)
        coverage_a.merge(coverage_b) do |_condition, branches_inside_a, branches_inside_b|
          branches_inside_a.merge(branches_inside_b) do |_branch, a_count, b_count|
            a_count + b_count
          end
        end
      end
    end
  end
end
