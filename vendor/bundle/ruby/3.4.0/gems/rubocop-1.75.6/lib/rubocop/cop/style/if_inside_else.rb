# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # If the `else` branch of a conditional consists solely of an `if` node,
      # it can be combined with the `else` to become an `elsif`.
      # This helps to keep the nesting level from getting too deep.
      #
      # @example
      #   # bad
      #   if condition_a
      #     action_a
      #   else
      #     if condition_b
      #       action_b
      #     else
      #       action_c
      #     end
      #   end
      #
      #   # good
      #   if condition_a
      #     action_a
      #   elsif condition_b
      #     action_b
      #   else
      #     action_c
      #   end
      #
      # @example AllowIfModifier: false (default)
      #   # bad
      #   if condition_a
      #     action_a
      #   else
      #     action_b if condition_b
      #   end
      #
      #   # good
      #   if condition_a
      #     action_a
      #   elsif condition_b
      #     action_b
      #   end
      #
      # @example AllowIfModifier: true
      #   # good
      #   if condition_a
      #     action_a
      #   else
      #     action_b if condition_b
      #   end
      #
      #   # good
      #   if condition_a
      #     action_a
      #   elsif condition_b
      #     action_b
      #   end
      #
      class IfInsideElse < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Convert `if` nested inside `else` to `elsif`.'

        # rubocop:disable Metrics/CyclomaticComplexity
        def on_if(node)
          return if node.ternary? || node.unless?

          else_branch = node.else_branch

          return unless else_branch&.if_type? && else_branch.if?
          return if allow_if_modifier_in_else_branch?(else_branch)

          add_offense(else_branch.loc.keyword) do |corrector|
            next if part_of_ignored_node?(node)

            autocorrect(corrector, else_branch)
            ignore_node(node)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        private

        def autocorrect(corrector, node)
          if then?(node)
            # If the nested `if` is a then node, correct it first,
            # then the next pass will use `correct_to_elsif_from_if_inside_else_form`
            IfThenCorrector.new(node, indentation: 0).call(corrector)
            return
          end

          if node.modifier_form?
            correct_to_elsif_from_modifier_form(corrector, node)
          else
            correct_to_elsif_from_if_inside_else_form(corrector, node, node.condition)
          end
        end

        def correct_to_elsif_from_modifier_form(corrector, node)
          corrector.replace(node.parent.loc.else, "elsif #{node.condition.source}")

          condition_range = range_between(
            node.if_branch.source_range.end_pos, node.condition.source_range.end_pos
          )
          corrector.remove(condition_range)
        end

        def correct_to_elsif_from_if_inside_else_form(corrector, node, condition) # rubocop:disable Metrics/AbcSize
          corrector.replace(node.parent.loc.else, "elsif #{condition.source}")

          if_condition_range = if_condition_range(node, condition)

          if (if_branch = node.if_branch)
            corrector.replace(if_condition_range, range_with_comments(if_branch).source)
            corrector.remove(range_with_comments_and_lines(if_branch))
          else
            corrector.remove(range_by_whole_lines(if_condition_range, include_final_newline: true))
          end

          corrector.remove(condition)
          corrector.remove(range_by_whole_lines(find_end_range(node), include_final_newline: true))
        end

        def then?(node)
          node.loc.begin&.source == 'then'
        end

        def find_end_range(node)
          end_range = node.loc.end
          return end_range if end_range

          find_end_range(node.parent)
        end

        def if_condition_range(node, condition)
          range_between(node.loc.keyword.begin_pos, condition.source_range.end_pos)
        end

        def allow_if_modifier_in_else_branch?(else_branch)
          allow_if_modifier? && else_branch&.modifier_form?
        end

        def allow_if_modifier?
          cop_config['AllowIfModifier']
        end
      end
    end
  end
end
