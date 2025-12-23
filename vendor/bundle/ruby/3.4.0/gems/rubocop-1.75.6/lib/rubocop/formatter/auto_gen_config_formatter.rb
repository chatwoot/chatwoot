# frozen_string_literal: true

module RuboCop
  module Formatter
    # Does not show individual offenses in the console.
    class AutoGenConfigFormatter < ProgressFormatter
      def finished(inspected_files)
        output.puts

        report_summary(inspected_files.size,
                       @total_offense_count,
                       @total_correction_count,
                       @total_correctable_count)
      end
    end
  end
end
