# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if empty lines exist around the bodies of methods.
      #
      # @example
      #
      #   # good
      #
      #   def foo
      #     # ...
      #   end
      #
      #   # bad
      #
      #   def bar
      #
      #     # ...
      #
      #   end
      class EmptyLinesAroundMethodBody < Base
        include EmptyLinesAroundBody
        extend AutoCorrector

        KIND = 'method'

        def on_def(node)
          if node.endless?
            return unless offending_endless_method?(node)

            register_offense_for_endless_method(node)
          else
            first_line = node.arguments.source_range&.last_line
            check(node, node.body, adjusted_first_line: first_line)
          end
        end
        alias on_defs on_def

        private

        def style
          :no_empty_lines
        end

        def offending_endless_method?(node)
          node.body.first_line > node.loc.assignment.line + 1 &&
            processed_source.lines[node.loc.assignment.line].empty?
        end

        def register_offense_for_endless_method(node)
          range = processed_source.buffer.line_range(node.loc.assignment.line + 1).resize(1)

          msg = message(MSG_EXTRA, 'beginning')

          add_offense(range, message: msg) do |corrector|
            corrector.remove(range)
          end
        end
      end
    end
  end
end
