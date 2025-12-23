# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for unnecessary conditional expressions.
      #
      # NOTE: Since the intention of the comment cannot be automatically determined,
      # autocorrection is not applied when a comment is used, as shown below:
      #
      # [source,ruby]
      # -----
      # if b
      #   # Important note.
      #   b
      # else
      #   c
      # end
      # -----
      #
      # @example
      #   # bad
      #   a = b ? b : c
      #
      #   # good
      #   a = b || c
      #
      #   # bad
      #   if b
      #     b
      #   else
      #     c
      #   end
      #
      #   # good
      #   b || c
      #
      #   # good
      #   if b
      #     b
      #   elsif cond
      #     c
      #   end
      #
      #   # bad
      #   a.nil? ? true : a
      #
      #   # good
      #   a.nil? || a
      #
      #   # bad
      #   if a.nil?
      #     true
      #   else
      #     a
      #   end
      #
      #   # good
      #   a.nil? || a
      #
      # @example AllowedMethods: ['nonzero?'] (default)
      #   # good
      #   num.nonzero? ? true : false
      #
      class RedundantCondition < Base
        include AllowedMethods
        include CommentsHelp
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use double pipes `||` instead.'
        REDUNDANT_CONDITION = 'This condition is not needed.'
        ARGUMENT_WITH_OPERATOR_TYPES = %i[
          splat block_pass forwarded_restarg forwarded_kwrestarg forwarded_args
        ].freeze

        def on_if(node)
          return if node.modifier_form? || node.elsif_conditional? || !offense?(node)

          message = message(node)

          add_offense(range_of_offense(node), message: message) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def message(node)
          if redundant_condition?(node)
            REDUNDANT_CONDITION
          else
            MSG
          end
        end

        def autocorrect(corrector, node)
          return if node.each_descendant.any? { |descendant| contains_comments?(descendant) }

          if node.ternary? && !branches_have_method?(node)
            correct_ternary(corrector, node)
          elsif redundant_condition?(node)
            corrector.replace(node, node.if_branch.source)
          else
            corrected = make_ternary_form(node)

            corrector.replace(node, corrected)
          end
        end

        def range_of_offense(node)
          return node.source_range unless node.ternary?
          return node.source_range if node.ternary? && branches_have_method?(node)

          range_between(node.loc.question.begin_pos, node.loc.colon.end_pos)
        end

        def offense?(node)
          _condition, _if_branch, else_branch = *node # rubocop:disable InternalAffairs/NodeDestructuring
          return false if use_if_branch?(else_branch) || use_hash_key_assignment?(else_branch)

          synonymous_condition_and_branch?(node) && !node.elsif? &&
            (node.ternary? || !else_branch.instance_of?(AST::Node) || else_branch.single_line?)
        end

        def redundant_condition?(node)
          node.modifier_form? || !node.else_branch
        end

        def use_if_branch?(else_branch)
          else_branch&.if_type?
        end

        def use_hash_key_assignment?(else_branch)
          else_branch&.send_type? && else_branch.method?(:[]=)
        end

        def use_hash_key_access?(node)
          node.send_type? && node.method?(:[])
        end

        def synonymous_condition_and_branch?(node)
          condition, if_branch, _else_branch = *node # rubocop:disable InternalAffairs/NodeDestructuring
          # e.g.
          #   if var
          #     var
          #   else
          #     'foo'
          #   end
          return true if condition == if_branch

          # e.g.
          #   a.nil? ? true : a
          # or
          #   if a.nil?
          #     true
          #   else
          #     a
          #   end
          return true if if_branch_is_true_type_and_else_is_not?(node)

          # e.g.
          #   if foo
          #     @value = foo
          #   else
          #     @value = another_value?
          #   end
          return true if branches_have_assignment?(node) && condition == if_branch.expression

          # e.g.
          #   if foo
          #     test.value = foo
          #   else
          #     test.value = another_value?
          #   end
          branches_have_method?(node) && condition == if_branch.first_argument &&
            !use_hash_key_access?(if_branch)
        end

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def if_branch_is_true_type_and_else_is_not?(node)
          return false unless node.ternary? || node.if?

          cond = node.condition
          return false unless cond.call_type?
          return false if !cond.predicate_method? || allowed_method?(cond.method_name)

          node.if_branch&.true_type? && node.else_branch && !node.else_branch.true_type?
        end
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def branches_have_assignment?(node)
          _condition, if_branch, else_branch = *node # rubocop:disable InternalAffairs/NodeDestructuring

          return false unless if_branch && else_branch

          asgn_type?(if_branch) && (if_branch_variable_name = if_branch.name) &&
            asgn_type?(else_branch) && (else_branch_variable_name = else_branch.name) &&
            if_branch_variable_name == else_branch_variable_name
        end

        def asgn_type?(node)
          node.type?(:lvasgn, :ivasgn, :cvasgn, :gvasgn)
        end

        def branches_have_method?(node)
          return false unless node.if_branch && node.else_branch

          single_argument_method?(node.if_branch) && single_argument_method?(node.else_branch) &&
            same_method?(node.if_branch, node.else_branch)
        end

        def single_argument_method?(node)
          return false if !node.send_type? || node.method?(:[]) || !node.arguments.one?

          !argument_with_operator?(node.first_argument)
        end

        def same_method?(if_branch, else_branch)
          if_branch.method?(else_branch.method_name) && if_branch.receiver == else_branch.receiver
        end

        # If the argument is using an operator, it is an invalid syntax.
        # e.g. `foo || *bar`, `foo || **bar`, and `foo || &bar`.
        def argument_with_operator?(argument)
          return true if ARGUMENT_WITH_OPERATOR_TYPES.include?(argument.type)
          return false unless argument.hash_type?
          return false unless (node = argument.children.first)

          node.type?(:kwsplat, :forwarded_kwrestarg)
        end

        def wrap_arguments_with_parens(condition)
          method = condition.source_range.begin.join(condition.loc.selector.end)
          arguments = condition.first_argument.source_range.begin.join(condition.source_range.end)

          "#{method.source}(#{arguments.source})"
        end

        # rubocop:disable Metrics/AbcSize
        def if_source(if_branch, arithmetic_operation)
          if branches_have_method?(if_branch.parent) && if_branch.parenthesized?
            if_branch.source.delete_suffix(')')
          elsif arithmetic_operation
            argument_source = if_branch.first_argument.source

            "#{if_branch.receiver.source} #{if_branch.method_name} (#{argument_source}"
          elsif if_branch.true_type?
            condition = if_branch.parent.condition
            return condition.source if condition.arguments.empty?

            wrap_arguments_with_parens(condition)
          else
            if_branch.source
          end
        end
        # rubocop:enable Metrics/AbcSize

        def else_source(else_branch, arithmetic_operation) # rubocop:disable Metrics/AbcSize
          if arithmetic_operation
            "#{else_branch.first_argument.source})"
          elsif branches_have_method?(else_branch.parent)
            else_source_if_has_method(else_branch)
          elsif require_parentheses?(else_branch)
            "(#{else_branch.source})"
          elsif without_argument_parentheses_method?(else_branch)
            "#{else_branch.method_name}(#{else_branch.arguments.map(&:source).join(', ')})"
          elsif branches_have_assignment?(else_branch.parent)
            else_source_if_has_assignment(else_branch)
          else
            else_branch.source
          end
        end

        def else_source_if_has_method(else_branch)
          if require_parentheses?(else_branch.first_argument)
            "(#{else_branch.first_argument.source})"
          elsif require_braces?(else_branch.first_argument)
            "{ #{else_branch.first_argument.source} }"
          else
            else_branch.first_argument.source
          end
        end

        def else_source_if_has_assignment(else_branch)
          if require_parentheses?(else_branch.expression)
            "(#{else_branch.expression.source})"
          elsif require_braces?(else_branch.expression)
            "{ #{else_branch.expression.source} }"
          else
            else_branch.expression.source
          end
        end

        def make_ternary_form(node)
          _condition, if_branch, else_branch = *node # rubocop:disable InternalAffairs/NodeDestructuring
          arithmetic_operation = use_arithmetic_operation?(if_branch)

          ternary_form = [
            if_source(if_branch, arithmetic_operation),
            else_source(else_branch, arithmetic_operation)
          ].join(' || ')
          ternary_form += ')' if branches_have_method?(node) && if_branch.parenthesized?

          if node.parent&.send_type?
            "(#{ternary_form})"
          else
            ternary_form
          end
        end

        def correct_ternary(corrector, node)
          corrector.replace(range_of_offense(node), '||')

          return unless node.else_branch.range_type?

          corrector.wrap(node.else_branch, '(', ')')
        end

        def require_parentheses?(node)
          (node.basic_conditional? && node.modifier_form?) ||
            node.range_type? ||
            node.rescue_type? ||
            (node.respond_to?(:semantic_operator?) && node.semantic_operator?)
        end

        def require_braces?(node)
          node.hash_type? && !node.braces?
        end

        def use_arithmetic_operation?(node)
          node.respond_to?(:arithmetic_operation?) && node.arithmetic_operation?
        end

        def without_argument_parentheses_method?(node)
          node.send_type? && !node.arguments.empty? &&
            !node.parenthesized? && !node.operator_method? && !node.assignment_method?
        end
      end
    end
  end
end
