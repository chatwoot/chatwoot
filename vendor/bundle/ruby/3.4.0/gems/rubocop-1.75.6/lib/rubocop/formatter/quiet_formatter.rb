# frozen_string_literal: true

module RuboCop
  module Formatter
    # If no offenses are found, no output is displayed.
    # Otherwise, SimpleTextFormatter's output is displayed.
    class QuietFormatter < SimpleTextFormatter
      def report_summary(file_count, offense_count, correction_count, correctable_count)
        super unless offense_count.zero?
      end
    end
  end
end
