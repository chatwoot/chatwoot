# frozen_string_literal: true

module SimpleCov
  module ExitCodes
    SUCCESS = 0
    EXCEPTION = 1
    MINIMUM_COVERAGE = 2
    MAXIMUM_COVERAGE_DROP = 3
  end
end

require_relative "exit_codes/exit_code_handling"
require_relative "exit_codes/maximum_coverage_drop_check"
require_relative "exit_codes/minimum_coverage_by_file_check"
require_relative "exit_codes/minimum_overall_coverage_check"
