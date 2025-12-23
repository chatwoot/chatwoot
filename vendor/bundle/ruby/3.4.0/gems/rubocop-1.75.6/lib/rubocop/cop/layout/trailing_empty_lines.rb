# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Looks for trailing blank lines and a final newline in the
      # source code.
      #
      # @example EnforcedStyle: final_newline (default)
      #   # `final_newline` looks for one newline at the end of files.
      #
      #   # bad
      #   class Foo; end
      #
      #   # EOF
      #
      #   # bad
      #   class Foo; end # EOF
      #
      #   # good
      #   class Foo; end
      #   # EOF
      #
      # @example EnforcedStyle: final_blank_line
      #   # `final_blank_line` looks for one blank line followed by a new line
      #   # at the end of files.
      #
      #   # bad
      #   class Foo; end
      #   # EOF
      #
      #   # bad
      #   class Foo; end # EOF
      #
      #   # good
      #   class Foo; end
      #
      #   # EOF
      #
      class TrailingEmptyLines < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        def on_new_investigation
          buffer = processed_source.buffer
          return if buffer.source.empty?

          # The extra text that comes after the last token could be __END__
          # followed by some data to read. If so, we don't check it because
          # there could be good reasons why it needs to end with a certain
          # number of newlines.
          return if ends_in_end?(processed_source)
          return if end_with_percent_blank_string?(processed_source)

          whitespace_at_end = buffer.source[/\s*\Z/]
          blank_lines = whitespace_at_end.count("\n") - 1
          wanted_blank_lines = style == :final_newline ? 0 : 1

          return unless blank_lines != wanted_blank_lines

          offense_detected(buffer, wanted_blank_lines, blank_lines, whitespace_at_end)
        end

        private

        def offense_detected(buffer, wanted_blank_lines, blank_lines, whitespace_at_end)
          begin_pos = buffer.source.length - whitespace_at_end.length
          autocorrect_range = range_between(begin_pos, buffer.source.length)
          begin_pos += 1 unless whitespace_at_end.empty?
          report_range = range_between(begin_pos, buffer.source.length)

          add_offense(
            report_range, message: message(wanted_blank_lines, blank_lines)
          ) do |corrector|
            corrector.replace(autocorrect_range, style == :final_newline ? "\n" : "\n\n")
          end
        end

        def ends_in_end?(processed_source)
          buffer = processed_source.buffer

          return true if buffer.source.match?(/\s*__END__/)
          return false if processed_source.tokens.empty?

          extra = buffer.source[processed_source.tokens.last.end_pos..]
          extra&.strip&.start_with?('__END__')
        end

        def end_with_percent_blank_string?(processed_source)
          processed_source.buffer.source.end_with?("%\n\n")
        end

        def message(wanted_blank_lines, blank_lines)
          case blank_lines
          when -1
            'Final newline missing.'
          when 0
            'Trailing blank line missing.'
          else
            instead_of = if wanted_blank_lines.zero?
                           ''
                         else
                           "instead of #{wanted_blank_lines} "
                         end
            format('%<current>d trailing blank lines %<prefer>sdetected.',
                   current: blank_lines, prefer: instead_of)
          end
        end
      end
    end
  end
end
