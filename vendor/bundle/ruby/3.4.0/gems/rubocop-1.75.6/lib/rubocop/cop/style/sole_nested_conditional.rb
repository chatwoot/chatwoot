# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # If the branch of a conditional consists solely of a conditional node,
      # its conditions can be combined with the conditions of the outer branch.
      # This helps to keep the nesting level from getting too deep.
      #
      # @example
      #   # bad
      #   if condition_a
      #     if condition_b
      #       do_something
      #     end
      #   end
      #
      #   # bad
      #   if condition_b
      #     do_something
      #   end if condition_a
      #
      #   # good
      #   if condition_a && condition_b
      #     do_something
      #   end
      #
      # @example AllowModifier: false (default)
      #   # bad
      #   if condition_a
      #     do_something if condition_b
      #   end
      #
      #   # bad
      #   if condition_b
      #     do_something
      #   end if condition_a
      #
      # @example AllowModifier: true
      #   # good
      #   if condition_a
      #     do_something if condition_b
      #   end
      #
      #   # good
      #   if condition_b
      #     do_something
      #   end if condition_a
      class SoleNestedConditional < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Consider merging nested conditions into outer `%<conditional_type>s` conditions.'

        def self.autocorrect_incompatible_with
          [Style::NegatedIf, Style::NegatedUnless]
        end

        def on_if(node)
          return if node.ternary? || node.else? || node.elsif?

          if_branch = node.if_branch
          return if use_variable_assignment_in_condition?(node.condition, if_branch)
          return unless offending_branch?(node, if_branch)

          message = format(MSG, conditional_type: node.keyword)
          add_offense(if_branch.loc.keyword, message: message) do |corrector|
            autocorrect(corrector, node, if_branch)
          end
        end

        private

        def use_variable_assignment_in_condition?(condition, if_branch)
          assigned_variables = assigned_variables(condition)

          assigned_variables && if_branch&.if_type? &&
            assigned_variables.include?(if_branch.condition.source)
        end

        def assigned_variables(condition)
          assigned_variables = condition.assignment? ? [condition.children.first.to_s] : []

          assigned_variables + condition.descendants.select(&:assignment?).map do |node|
            node.children.first.to_s
          end
        end

        def offending_branch?(node, branch)
          return false unless branch

          branch.if_type? &&
            !branch.else? &&
            !branch.ternary? &&
            !((node.modifier_form? || branch.modifier_form?) && allow_modifier?)
        end

        def autocorrect(corrector, node, if_branch)
          if node.modifier_form?
            autocorrect_outer_condition_modify_form(corrector, node, if_branch)
          else
            autocorrect_outer_condition_basic(corrector, node, if_branch)
          end
        end

        def autocorrect_outer_condition_basic(corrector, node, if_branch)
          correct_node(corrector, node)

          if if_branch.modifier_form?
            correct_for_guard_condition_style(corrector, node, if_branch)
          else
            correct_for_basic_condition_style(corrector, node, if_branch)
            correct_for_comment(corrector, node, if_branch)
          end
        end

        def correct_node(corrector, node)
          corrector.replace(node.loc.keyword, 'if') if node.unless?
          corrector.replace(node.condition, chainable_condition(node))
        end

        def correct_for_guard_condition_style(corrector, node, if_branch)
          corrector.insert_after(node.condition, " && #{chainable_condition(if_branch)}")

          range = range_between(
            if_branch.loc.keyword.begin_pos, if_branch.condition.source_range.end_pos
          )
          corrector.remove(range_with_surrounding_space(range, newlines: false))
        end

        def correct_for_basic_condition_style(corrector, node, if_branch)
          range = range_between(
            node.condition.source_range.end_pos, if_branch.condition.source_range.begin_pos
          )
          corrector.replace(range, ' && ')

          corrector.replace(if_branch.condition, chainable_condition(if_branch))

          corrector.remove(range_by_whole_lines(node.loc.end, include_final_newline: true))
        end

        def autocorrect_outer_condition_modify_form(corrector, node, if_branch)
          correct_node(corrector, if_branch)

          corrector.insert_before(if_branch.condition, "#{chainable_condition(node)} && ")

          range = range_between(node.loc.keyword.begin_pos, node.condition.source_range.end_pos)
          corrector.remove(range_with_surrounding_space(range, newlines: false))
        end

        def correct_for_comment(corrector, node, if_branch)
          comments = processed_source.ast_with_comments[if_branch].select do |comment|
            comment.loc.line < if_branch.condition.first_line
          end
          comment_text = comments.map(&:text).join("\n") << "\n"

          corrector.insert_before(node.loc.keyword, comment_text) unless comments.empty?
        end

        def chainable_condition(node)
          wrapped_condition = add_parentheses_if_needed(node.condition)

          return wrapped_condition if node.if?

          node.condition.and_type? ? "!(#{wrapped_condition})" : "!#{wrapped_condition}"
        end

        def add_parentheses_if_needed(condition)
          # Handle `send` and `block` nodes that need to be wrapped in parens
          # FIXME: autocorrection prevents syntax errors by wrapping the entire node in parens,
          #        but wrapping the argument list would be a more ergonomic correction.
          node_to_check = condition&.any_block_type? ? condition.send_node : condition
          return condition.source unless add_parentheses?(node_to_check)

          if parenthesize_method?(condition)
            parenthesized_method_arguments(condition)
          else
            "(#{condition.source})"
          end
        end

        def parenthesize_method?(node)
          node.call_type? && node.arguments.any? && !node.parenthesized? &&
            !node.comparison_method? && !node.operator_method?
        end

        def add_parentheses?(node)
          return true if node.assignment? || (node.operator_keyword? && !node.and_type?)
          return false unless node.call_type?

          (node.arguments.any? && !node.parenthesized?) || node.prefix_not?
        end

        def parenthesized_method_arguments(node)
          method_call = node.source_range.begin.join(node.loc.selector.end).source
          arguments = node.first_argument.source_range.begin.join(node.source_range.end).source

          "#{method_call}(#{arguments})"
        end

        def allow_modifier?
          cop_config['AllowModifier']
        end
      end
    end
  end
end
