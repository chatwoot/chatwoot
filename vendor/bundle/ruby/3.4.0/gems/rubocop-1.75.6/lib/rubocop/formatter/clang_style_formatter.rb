# frozen_string_literal: true

module RuboCop
  module Formatter
    # This formatter formats report data in clang style.
    # The precise location of the problem is shown together with the
    # relevant source code.
    class ClangStyleFormatter < SimpleTextFormatter
      ELLIPSES = '...'

      def report_file(file, offenses)
        offenses.each { |offense| report_offense(file, offense) }
      end

      private

      def report_offense(file, offense)
        output.printf(
          "%<path>s:%<line>d:%<column>d: %<severity>s: %<message>s\n",
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

      def valid_line?(offense)
        !offense.location.source_line.blank?
      end

      def report_line(location)
        source_line = location.source_line

        if location.single_line?
          output.puts(source_line)
        else
          output.puts("#{source_line} #{yellow(ELLIPSES)}")
        end
      end

      def report_highlighted_area(highlighted_area)
        space_area  = highlighted_area.source_buffer.slice(0...highlighted_area.begin_pos)
        source_area = highlighted_area.source
        output.puts("#{' ' * Unicode::DisplayWidth.of(space_area)}" \
                    "#{'^' * Unicode::DisplayWidth.of(source_area)}")
      end
    end
  end
end
