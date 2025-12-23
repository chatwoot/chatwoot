# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the . position in multi-line method calls.
      #
      # @example EnforcedStyle: leading (default)
      #   # bad
      #   something.
      #     method
      #
      #   # good
      #   something
      #     .method
      #
      # @example EnforcedStyle: trailing
      #   # bad
      #   something
      #     .method
      #
      #   # good
      #   something.
      #     method
      class DotPosition < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        def self.autocorrect_incompatible_with
          [Style::RedundantSelf]
        end

        def on_send(node)
          return unless node.dot? || node.safe_navigation?

          return correct_style_detected if proper_dot_position?(node)

          opposite_style_detected
          dot = node.loc.dot
          message = message(dot)

          add_offense(dot, message: message) { |corrector| autocorrect(corrector, dot, node) }
        end
        alias on_csend on_send

        private

        def autocorrect(corrector, dot, node)
          dot_range = if processed_source[dot.line - 1].strip == '.'
                        range_by_whole_lines(dot, include_final_newline: true)
                      else
                        dot
                      end
          corrector.remove(dot_range)
          case style
          when :leading
            corrector.insert_before(selector_range(node), dot.source)
          when :trailing
            corrector.insert_after(node.receiver, dot.source)
          end
        end

        def message(dot)
          "Place the #{dot.source} on the " +
            case style
            when :leading
              'next line, together with the method name.'
            when :trailing
              'previous line, together with the method call receiver.'
            end
        end

        def proper_dot_position?(node)
          selector_range = selector_range(node)

          return true if same_line?(selector_range, end_range(node.receiver))

          selector_line = selector_range.line
          receiver_line = receiver_end_line(node.receiver)
          dot_line = node.loc.dot.line

          # don't register an offense if there is a line comment between the
          # dot and the selector otherwise, we might break the code while
          # "correcting" it (even if there is just an extra blank line, treat
          # it the same)
          # Also, in the case of a heredoc, the receiver will end after the dot,
          # because the heredoc body is on subsequent lines, so use the highest
          # line to compare to.
          return true if line_between?(selector_line, [receiver_line, dot_line].max)

          correct_dot_position_style?(dot_line, selector_line)
        end

        def line_between?(first_line, second_line)
          (first_line - second_line) > 1
        end

        def correct_dot_position_style?(dot_line, selector_line)
          case style
          when :leading then dot_line == selector_line
          when :trailing then dot_line != selector_line
          end
        end

        def receiver_end_line(node)
          if (line = last_heredoc_line(node))
            line
          else
            node.source_range.end.line
          end
        end

        def last_heredoc_line(node)
          if node.send_type?
            node.arguments.select { |arg| heredoc?(arg) }.map { |arg| arg.loc.heredoc_end.line }.max
          elsif heredoc?(node)
            node.loc.heredoc_end.line
          end
        end

        def heredoc?(node)
          node.type?(:str, :dstr) && node.heredoc?
        end

        def end_range(node)
          node.source_range.end
        end

        def selector_range(node)
          return node unless node.call_type?

          # l.(1) has no selector, so we use the opening parenthesis instead
          node.loc.selector || node.loc.begin
        end
      end
    end
  end
end
