# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Enforces empty line after multiline condition.
      #
      # @example
      #   # bad
      #   if multiline &&
      #     condition
      #     do_something
      #   end
      #
      #   # good
      #   if multiline &&
      #     condition
      #
      #     do_something
      #   end
      #
      #   # bad
      #   case x
      #   when foo,
      #     bar
      #     do_something
      #   end
      #
      #   # good
      #   case x
      #   when foo,
      #     bar
      #
      #     do_something
      #   end
      #
      #   # bad
      #   begin
      #     do_something
      #   rescue FooError,
      #     BarError
      #     handle_error
      #   end
      #
      #   # good
      #   begin
      #     do_something
      #   rescue FooError,
      #     BarError
      #
      #     handle_error
      #   end
      #
      class EmptyLineAfterMultilineCondition < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use empty line after multiline condition.'

        def on_if(node)
          return if node.ternary?

          if node.modifier_form?
            check_condition(node.condition) if node.right_sibling
          else
            check_condition(node.condition)
          end
        end

        def on_while(node)
          check_condition(node.condition)
        end
        alias on_until on_while

        def on_while_post(node)
          return unless node.right_sibling

          check_condition(node.condition)
        end
        alias on_until_post on_while_post

        def on_case(node)
          node.when_branches.each do |when_node|
            last_condition = when_node.conditions.last

            next if !multiline_when_condition?(when_node) ||
                    next_line_empty?(last_condition.last_line)

            add_offense(when_node, &autocorrect(last_condition))
          end
        end

        def on_rescue(node)
          node.resbody_branches.each do |resbody|
            rescued_exceptions = resbody.exceptions
            next if !multiline_rescue_exceptions?(rescued_exceptions) ||
                    next_line_empty?(rescued_exceptions.last.last_line)

            add_offense(resbody, &autocorrect(rescued_exceptions.last))
          end
        end

        private

        def check_condition(condition)
          return unless condition.multiline?
          return if next_line_empty?(condition.last_line)

          add_offense(condition, &autocorrect(condition))
        end

        def next_line_empty?(line)
          processed_source[line].blank?
        end

        def multiline_when_condition?(when_node)
          when_node.conditions.first.first_line != when_node.conditions.last.last_line
        end

        def multiline_rescue_exceptions?(exception_nodes)
          return false if exception_nodes.size <= 1

          first, *_rest, last = *exception_nodes
          first.first_line != last.last_line
        end

        def autocorrect(node)
          lambda do |corrector|
            range = range_by_whole_lines(node.source_range)
            corrector.insert_after(range, "\n")
          end
        end
      end
    end
  end
end
