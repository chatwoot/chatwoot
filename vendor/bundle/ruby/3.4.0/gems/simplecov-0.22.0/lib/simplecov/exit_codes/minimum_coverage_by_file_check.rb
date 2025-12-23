# frozen_string_literal: true

module SimpleCov
  module ExitCodes
    class MinimumCoverageByFileCheck
      def initialize(result, minimum_coverage_by_file)
        @result = result
        @minimum_coverage_by_file = minimum_coverage_by_file
      end

      def failing?
        minimum_violations.any?
      end

      def report
        minimum_violations.each do |violation|
          $stderr.printf(
            "%<criterion>s coverage by file (%<covered>.2f%%) is below the expected minimum coverage (%<minimum_coverage>.2f%%).\n",
            covered: SimpleCov.round_coverage(violation.fetch(:actual)),
            minimum_coverage: violation.fetch(:minimum_expected),
            criterion: violation.fetch(:criterion).capitalize
          )
        end
      end

      def exit_code
        SimpleCov::ExitCodes::MINIMUM_COVERAGE
      end

    private

      attr_reader :result, :minimum_coverage_by_file

      def minimum_violations
        @minimum_violations ||=
          compute_minimum_coverage_data.select do |achieved|
            achieved.fetch(:actual) < achieved.fetch(:minimum_expected)
          end
      end

      def compute_minimum_coverage_data
        minimum_coverage_by_file.flat_map do |criterion, expected_percent|
          result.coverage_statistics_by_file.fetch(criterion).map do |actual_coverage|
            {
              criterion: criterion,
              minimum_expected: expected_percent,
              actual: SimpleCov.round_coverage(actual_coverage.percent)
            }
          end
        end
      end
    end
  end
end
