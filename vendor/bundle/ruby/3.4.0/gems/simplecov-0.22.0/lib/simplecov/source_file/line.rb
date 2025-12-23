# frozen_string_literal: true

module SimpleCov
  class SourceFile
    # Representation of a single line in a source file including
    # this specific line's source code, line_number and code coverage,
    # with the coverage being either nil (coverage not applicable, e.g. comment
    # line), 0 (line not covered) or >1 (the amount of times the line was
    # executed)
    class Line
      # The source code for this line. Aliased as :source
      attr_reader :src
      # The line number in the source file. Aliased as :line, :number
      attr_reader :line_number
      # The coverage data for this line: either nil (never), 0 (missed) or >=1 (times covered)
      attr_reader :coverage
      # Whether this line was skipped
      attr_reader :skipped

      # Lets grab some fancy aliases, shall we?
      alias source src
      alias line line_number
      alias number line_number

      def initialize(src, line_number, coverage)
        raise ArgumentError, "Only String accepted for source" unless src.is_a?(String)
        raise ArgumentError, "Only Integer accepted for line_number" unless line_number.is_a?(Integer)
        raise ArgumentError, "Only Integer and nil accepted for coverage" unless coverage.is_a?(Integer) || coverage.nil?

        @src         = src
        @line_number = line_number
        @coverage    = coverage
        @skipped     = false
      end

      # Returns true if this is a line that should have been covered, but was not
      def missed?
        !never? && !skipped? && coverage.zero?
      end

      # Returns true if this is a line that has been covered
      def covered?
        !never? && !skipped? && coverage.positive?
      end

      # Returns true if this line is not relevant for coverage
      def never?
        !skipped? && coverage.nil?
      end

      # Flags this line as skipped
      def skipped!
        @skipped = true
      end

      # Returns true if this line was skipped, false otherwise. Lines are skipped if they are wrapped with
      # # :nocov: comment lines.
      def skipped?
        skipped
      end

      # The status of this line - either covered, missed, skipped or never. Useful i.e. for direct use
      # as a css class in report generation
      def status
        return "skipped" if skipped?
        return "never" if never?
        return "missed" if missed?
        return "covered" if covered?
      end
    end
  end
end
