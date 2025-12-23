# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter display dots for files with no offenses and
    # letters for files with problems in the them. In the end it
    # appends the regular report data in the clang style format.
    class ProgressFormatter < ClangStyleFormatter
      include TextUtil

      DOT = '.'

      def initialize(output, options = {})
        super
        @dot = green(DOT)
      end

      def started(target_files)
        super
        @offenses_for_files = {}
        output.puts "Inspecting #{pluralize(target_files.size, 'file')}"
      end

      def file_finished(file, offenses)
        unless offenses.empty?
          count_stats(offenses)
          @offenses_for_files[file] = offenses
        end

        report_file_as_mark(offenses)
      end

      def finished(inspected_files)
        output.puts

        unless @offenses_for_files.empty?
          output.puts
          output.puts 'Offenses:'
          output.puts

          @offenses_for_files.each { |file, offenses| report_file(file, offenses) }
        end

        report_summary(inspected_files.size,
                       @total_offense_count,
                       @total_correction_count,
                       @total_correctable_count)
      end

      def report_file_as_mark(offenses)
        mark = if offenses.empty?
                 @dot
               else
                 highest_offense = offenses.max_by(&:severity)
                 colored_severity_code(highest_offense)
               end

        output.write mark
      end
    end
  end
end
