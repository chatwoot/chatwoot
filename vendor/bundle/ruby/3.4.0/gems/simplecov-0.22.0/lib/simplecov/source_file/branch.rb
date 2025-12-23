# frozen_string_literal: true

module SimpleCov
  class SourceFile
    #
    # Representing single branch that has been detected in coverage report.
    # Give us support methods that handle needed calculations.
    class Branch
      attr_reader :start_line, :end_line, :coverage, :type

      # rubocop:disable Metrics/ParameterLists
      def initialize(start_line:, end_line:, coverage:, inline:, type:)
        @start_line = start_line
        @end_line   = end_line
        @coverage   = coverage
        @inline     = inline
        @type       = type
        @skipped    = false
      end
      # rubocop:enable Metrics/ParameterLists

      def inline?
        @inline
      end

      #
      # Return true if there is relevant count defined > 0
      #
      # @return [Boolean]
      #
      def covered?
        !skipped? && coverage.positive?
      end

      #
      # Check if branche missed or not
      #
      # @return [Boolean]
      #
      def missed?
        !skipped? && coverage.zero?
      end

      # The line on which we want to report the coverage
      #
      # Usually we choose the line above the start of the branch (so that it shows up
      # at if/else) because that
      # * highlights the condition
      # * makes it distinguishable if the first line of the branch is an inline branch
      #   (see the nested_branches fixture)
      #
      def report_line
        if inline?
          start_line
        else
          start_line - 1
        end
      end

      # Flags the branch as skipped
      def skipped!
        @skipped = true
      end

      # Returns true if the branch was marked skipped by virtue of nocov comments.
      def skipped?
        @skipped
      end

      def overlaps_with?(line_range)
        start_line <= line_range.end && end_line >= line_range.begin
      end

      #
      # Return array with coverage count and badge
      #
      # @return [Array]
      #
      def report
        [type, coverage]
      end
    end
  end
end
