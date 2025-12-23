# frozen_string_literal: true

module SimpleCov
  module ExitCodes
    module ExitCodeHandling
    module_function

      def call(result, coverage_limits:)
        checks = coverage_checks(result, coverage_limits)

        failing_check = checks.find(&:failing?)
        if failing_check
          failing_check.report
          failing_check.exit_code
        else
          SimpleCov::ExitCodes::SUCCESS
        end
      end

      def coverage_checks(result, coverage_limits)
        [
          MinimumOverallCoverageCheck.new(result, coverage_limits.minimum_coverage),
          MinimumCoverageByFileCheck.new(result, coverage_limits.minimum_coverage_by_file),
          MaximumCoverageDropCheck.new(result, coverage_limits.maximum_coverage_drop)
        ]
      end
    end
  end
end
