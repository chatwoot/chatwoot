# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for literals used as the conditions or as
      # operands in and/or expressions serving as the conditions of
      # if/while/until/case-when/case-in.
      #
      # NOTE: Literals in `case-in` condition where the match variable is used in
      # `in` are accepted as a pattern matching.
      #
      # @example
      #
      #   # bad
      #   if 20
      #     do_something
      #   end
      #
      #   # bad
      #   # We're only interested in the left hand side being a truthy literal,
      #   # because it affects the evaluation of the &&, whereas the right hand
      #   # side will be conditionally executed/called and can be a literal.
      #   if true && some_var
      #     do_something
      #   end
      #
      #   # good
      #   if some_var
      #     do_something
      #   end
      #
      #   # good
      #   # When using a boolean value for an infinite loop.
      #   while true
      #     break if condition
      #   end
      class LiteralAsCondition < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Literal `%<literal>s` appeared as a condition.'
        RESTRICT_ON_SEND = [:!].freeze

        def on_and(node)
          return unless node.lhs.truthy_literal?

          add_offense(node.lhs) do |corrector|
            # Don't autocorrect `'foo' && return` because having `return` as
            # the leftmost node can lead to a void value expression syntax error.
            next if node.rhs.type?(:return, :break, :next)

            corrector.replace(node, node.rhs.source)
          end
        end

        def on_if(node)
          cond = condition(node)

          return unless cond.falsey_literal? || cond.truthy_literal?

          correct_if_node(node, cond)
        end

        def on_while(node)
          return if node.condition.source == 'true'

          if node.condition.truthy_literal?
            add_offense(node.condition) do |corrector|
              corrector.replace(node.condition, 'true')
            end
          elsif node.condition.falsey_literal?
            add_offense(node.condition) do |corrector|
              corrector.remove(node)
            end
          end
        end

        # rubocop:disable Metrics/AbcSize
        def on_while_post(node)
          return if node.condition.source == 'true'

          if node.condition.truthy_literal?
            add_offense(node.condition) do |corrector|
              corrector.replace(node, node.source.sub(node.condition.source, 'true'))
            end
          elsif node.condition.falsey_literal?
            add_offense(node.condition) do |corrector|
              corrector.replace(node, node.body.child_nodes.map(&:source).join("\n"))
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        def on_until(node)
          return if node.condition.source == 'false'

          if node.condition.falsey_literal?
            add_offense(node.condition) do |corrector|
              corrector.replace(node.condition, 'false')
            end
          elsif node.condition.truthy_literal?
            add_offense(node.condition) do |corrector|
              corrector.remove(node)
            end
          end
        end

        # rubocop:disable Metrics/AbcSize
        def on_until_post(node)
          return if node.condition.source == 'false'

          if node.condition.falsey_literal?
            add_offense(node.condition) do |corrector|
              corrector.replace(node, node.source.sub(node.condition.source, 'false'))
            end
          elsif node.condition.truthy_literal?
            add_offense(node.condition) do |corrector|
              corrector.replace(node, node.body.child_nodes.map(&:source).join("\n"))
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        def on_case(case_node)
          if case_node.condition
            check_case(case_node)
          else
            case_node.when_branches.each do |when_node|
              next unless when_node.conditions.all?(&:literal?)

              range = when_conditions_range(when_node)
              message = message(range)

              add_offense(range, message: message)
            end
          end
        end

        def on_case_match(case_match_node)
          if case_match_node.condition
            return if case_match_node.descendants.any?(&:match_var_type?)

            check_case(case_match_node)
          else
            case_match_node.each_in_pattern do |in_pattern_node|
              next unless in_pattern_node.condition.literal?

              add_offense(in_pattern_node)
            end
          end
        end

        def on_send(node)
          return unless node.negation_method?

          check_for_literal(node)
        end

        def message(node)
          format(MSG, literal: node.source)
        end

        private

        def check_for_literal(node)
          cond = condition(node)
          if cond.literal?
            add_offense(cond)
          else
            check_node(cond)
          end
        end

        def basic_literal?(node)
          if node.array_type?
            primitive_array?(node)
          else
            node.basic_literal?
          end
        end

        def primitive_array?(node)
          node.children.all? { |n| basic_literal?(n) }
        end

        def check_node(node)
          if node.send_type? && node.prefix_bang?
            handle_node(node.receiver)
          elsif node.operator_keyword?
            node.each_child_node { |op| handle_node(op) }
          elsif node.begin_type? && node.children.one?
            handle_node(node.children.first)
          end
        end

        def handle_node(node)
          if node.literal?
            return if node.parent.and_type?

            add_offense(node)
          elsif %i[send and or begin].include?(node.type)
            check_node(node)
          end
        end

        def check_case(case_node)
          condition = case_node.condition

          return if condition.array_type? && !primitive_array?(condition)
          return if condition.dstr_type?

          handle_node(condition)
        end

        def condition(node)
          if node.send_type?
            node.receiver
          else
            node.condition
          end
        end

        def when_conditions_range(when_node)
          range_between(
            when_node.conditions.first.source_range.begin_pos,
            when_node.conditions.last.source_range.end_pos
          )
        end

        def condition_evaluation(node, cond)
          if node.unless?
            cond.falsey_literal?
          else
            cond.truthy_literal?
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def correct_if_node(node, cond)
          result = condition_evaluation(node, cond)

          if node.elsif? && result
            add_offense(cond) do |corrector|
              corrector.replace(node, "else\n  #{node.if_branch.source}")
            end
          elsif node.elsif? && !result
            add_offense(cond) do |corrector|
              corrector.replace(node, "else\n  #{node.else_branch.source}")
            end
          elsif node.if_branch && result
            add_offense(cond) do |corrector|
              corrector.replace(node, node.if_branch.source)
            end
          elsif node.elsif_conditional?
            add_offense(cond) do |corrector|
              corrector.replace(node, "#{node.else_branch.source.sub('elsif', 'if')}\nend")
            end
          elsif node.else? || node.ternary?
            add_offense(cond) do |corrector|
              corrector.replace(node, node.else_branch.source)
            end
          else
            add_offense(cond) do |corrector|
              corrector.remove(node)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      end
    end
  end
end
