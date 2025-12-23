# frozen_string_literal: true

module SimpleCov
  module Combine
    # There might be reports from different kinds of tests,
    # e.g. RSpec and Cucumber. We need to combine their results
    # into unified one. This class does that.
    # To unite the results on file basis, it leverages
    # the combine of lines and branches inside each file within given results.
    module ResultsCombiner
    module_function

      #
      # Combine process explanation
      # => ResultCombiner: define all present files between results and start combine on file level.
      # ==> FileCombiner: collect result of next combine levels lines and branches.
      # ===> LinesCombiner: combine lines results.
      # ===> BranchesCombiner: combine branches results.
      #
      # @return [Hash]
      #
      def combine(*results)
        results.reduce({}) do |combined_results, next_result|
          combine_result_sets(combined_results, next_result)
        end
      end

      #
      # Manage combining results on files level
      #
      # @param [Hash] combined_results
      # @param [Hash] result
      #
      # @return [Hash]
      #
      def combine_result_sets(combined_results, result)
        results_files = combined_results.keys | result.keys

        results_files.each_with_object({}) do |file_name, file_combination|
          file_combination[file_name] = combine_file_coverage(
            combined_results[file_name],
            result[file_name]
          )
        end
      end

      #
      # Combine two files coverage results
      #
      # @param [Hash] coverage_a
      # @param [Hash] coverage_b
      #
      # @return [Hash]
      #
      def combine_file_coverage(coverage_a, coverage_b)
        Combine.combine(Combine::FilesCombiner, coverage_a, coverage_b)
      end
    end
  end
end
