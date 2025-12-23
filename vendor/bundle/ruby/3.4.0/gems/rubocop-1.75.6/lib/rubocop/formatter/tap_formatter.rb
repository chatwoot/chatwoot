# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter formats report data using the Test Anything Protocol.
    # TAP allows for to communicate tests results in a language agnostics way.
    class TapFormatter < ClangStyleFormatter
      def started(target_files)
        super
        @progress_count = 1
        output.puts "1..#{target_files.size}"
      end

      def file_finished(file, offenses)
        if offenses.empty?
          output.puts "ok #{@progress_count} - #{smart_path(file)}"
        else
          output.puts "not ok #{@progress_count} - #{smart_path(file)}"

          count_stats(offenses)
          report_file(file, offenses)
        end

        @progress_count += 1
      end

      private

      def report_line(location)
        source_line = location.source_line

        if location.single_line?
          output.puts("# #{source_line}")
        else
          output.puts("# #{source_line} #{yellow(ELLIPSES)}")
        end
      end

      def report_highlighted_area(highlighted_area)
        space_area  = highlighted_area.source_buffer.slice(0...highlighted_area.begin_pos)
        source_area = highlighted_area.source
        output.puts("# #{' ' * Unicode::DisplayWidth.of(space_area)}" \
                    "#{'^' * Unicode::DisplayWidth.of(source_area)}")
      end

      def report_offense(file, offense)
        output.printf(
          "# %<path>s:%<line>d:%<column>d: %<severity>s: %<message>s\n",
          path: cyan(smart_path(file)),
          line: offense.line,
          column: offense.real_column,
          severity: colored_severity_code(offense),
          message: message(offense)
        )

        return unless valid_line?(offense)

        report_line(offense.location)
        report_highlighted_area(offense.highlighted_area)
      end

      def annotate_message(msg)
        msg.gsub(/`(.*?)`/, '\1')
      end

      def message(offense)
        message =
          if offense.corrected_with_todo?
            '[Todo] '
          elsif offense.corrected?
            '[Corrected] '
          elsif offense.correctable?
            '[Correctable] '
          else
            ''
          end

        "#{message}#{annotate_message(offense.message)}"
      end
    end
  end
end
