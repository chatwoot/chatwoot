# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of here document closings.
      #
      # @example
      #
      #   # bad
      #   class Foo
      #     def bar
      #       <<~SQL
      #         'Hi'
      #     SQL
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     def bar
      #       <<~SQL
      #         'Hi'
      #       SQL
      #     end
      #   end
      #
      #   # bad
      #
      #   # heredoc contents is before closing heredoc.
      #   foo arg,
      #       <<~EOS
      #     Hi
      #       EOS
      #
      #   # good
      #   foo arg,
      #       <<~EOS
      #     Hi
      #   EOS
      #
      #   # good
      #   foo arg,
      #       <<~EOS
      #         Hi
      #       EOS
      #
      class ClosingHeredocIndentation < Base
        include Heredoc
        extend AutoCorrector

        SIMPLE_HEREDOC = '<<'
        MSG = '`%<closing>s` is not aligned with `%<opening>s`.'
        MSG_ARG = '`%<closing>s` is not aligned with `%<opening>s` or ' \
                  'beginning of method definition.'

        def on_heredoc(node)
          return if heredoc_type(node) == SIMPLE_HEREDOC ||
                    opening_indentation(node) == closing_indentation(node) ||
                    argument_indentation_correct?(node)

          message = message(node)
          add_offense(node.loc.heredoc_end, message: message) do |corrector|
            corrector.replace(node.loc.heredoc_end, indented_end(node))
          end
        end

        private

        def opening_indentation(node)
          indent_level(heredoc_opening(node))
        end

        def argument_indentation_correct?(node)
          return false unless node.argument? || node.chained?

          opening_indentation(
            find_node_used_heredoc_argument(node.parent)
          ) == closing_indentation(node)
        end

        def closing_indentation(node)
          indent_level(heredoc_closing(node))
        end

        def heredoc_opening(node)
          node.source_range.source_line
        end

        def heredoc_closing(node)
          node.loc.heredoc_end.source_line
        end

        def indented_end(node)
          closing_indent = closing_indentation(node)
          opening_indent = opening_indentation(node)
          closing_text = heredoc_closing(node)
          closing_text.gsub(/^\s{#{closing_indent}}/, ' ' * opening_indent)
        end

        def find_node_used_heredoc_argument(node)
          if node.parent&.send_type?
            find_node_used_heredoc_argument(node.parent)
          else
            node
          end
        end

        def message(node)
          format(
            node.argument? ? MSG_ARG : MSG,
            closing: heredoc_closing(node).strip,
            opening: heredoc_opening(node).strip
          )
        end

        def indent_level(source_line)
          source_line[/\A */].length
        end
      end
    end
  end
end
