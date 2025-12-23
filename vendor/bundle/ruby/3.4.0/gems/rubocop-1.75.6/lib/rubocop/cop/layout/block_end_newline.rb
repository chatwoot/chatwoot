# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks whether the end statement of a do..end block
      # is on its own line.
      #
      # @example
      #   # bad
      #   blah do |i|
      #     foo(i) end
      #
      #   # good
      #   blah do |i|
      #     foo(i)
      #   end
      #
      #   # bad
      #   blah { |i|
      #     foo(i) }
      #
      #   # good
      #   blah { |i|
      #     foo(i)
      #   }
      class BlockEndNewline < Base
        include Alignment
        extend AutoCorrector

        MSG = 'Expression at %<line>d, %<column>d should be on its own line.'

        def on_block(node)
          return if node.single_line?

          # If the end is on its own line, there is no offense
          return if begins_its_line?(node.loc.end)

          offense_range = offense_range(node)
          return if offense_range.source.lstrip.start_with?(';')

          register_offense(node, offense_range)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def register_offense(node, offense_range)
          add_offense(node.loc.end, message: message(node)) do |corrector|
            replacement = "\n#{offense_range.source.lstrip}"

            if (heredoc = last_heredoc_argument(node.body))
              corrector.remove(offense_range)
              corrector.insert_after(heredoc.loc.heredoc_end, replacement)
            else
              corrector.replace(offense_range, replacement)
            end
          end
        end

        def message(node)
          format(MSG, line: node.loc.end.line, column: node.loc.end.column + 1)
        end

        def last_heredoc_argument(node)
          return unless node&.call_type?
          return unless (arguments = node&.arguments)

          heredoc = arguments.reverse.detect { |arg| arg.str_type? && arg.heredoc? }
          return heredoc if heredoc

          last_heredoc_argument(node.children.first)
        end

        def offense_range(node)
          node.children.compact.last.source_range.end.join(node.loc.end)
        end
      end
    end
  end
end
