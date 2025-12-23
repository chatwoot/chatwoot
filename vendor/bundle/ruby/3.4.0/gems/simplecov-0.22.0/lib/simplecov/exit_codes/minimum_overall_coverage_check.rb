# frozen_string_literal: true

module SimpleCov
  module ExitCodes
    class MinimumOverallCoverageCheck
      def initialize(result, minimum_coverage)
        @result = result
        @minimum_coverage = minimum_coverage
      end

      def failing?
        minimum_violations.any?
      end

      def report
        minimum_violations.each do |violation|
          $stderr.printf(
            "%<criterion>s coverage (%<covered>.2f%%) is below the expected minimum coverage (%<minimum_coverage>.2f%%).\n",
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

      attr_reader :result, :minimum_coverage

      def minimum_violations
        @minimum_violations ||= calculate_minimum_violations
      end

      def calculate_minimum_violations
        coverage_achieved = minimum_coverage.map do |criterion, percent|
          {
            criterion: criterion,
            minimum_expected: percent,
            actual: result.coverage_statistics.fetch(criterion).percent
          }
        end

        coverage_achieved.select do |achieved|
          achieved.fetch(:actual) < achieved.fetch(:minimum_expected)
        end
      end
    end
  end
end
