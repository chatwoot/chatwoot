# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for identical expressions at the beginning or end of
      # each branch of a conditional expression. Such expressions should normally
      # be placed outside the conditional expression - before or after it.
      #
      # NOTE: The cop is poorly named and some people might think that it actually
      # checks for duplicated conditional branches. The name will probably be changed
      # in a future major RuboCop release.
      #
      # @safety
      #   Autocorrection is unsafe because changing the order of method invocations
      #   may change the behavior of the code. For example:
      #
      #   [source,ruby]
      #   ----
      #   if method_that_modifies_global_state # 1
      #     method_that_relies_on_global_state # 2
      #     foo                                # 3
      #   else
      #     method_that_relies_on_global_state # 2
      #     bar                                # 3
      #   end
      #   ----
      #
      #   In this example, `method_that_relies_on_global_state` will be moved before
      #   `method_that_modifies_global_state`, which changes the behavior of the program.
      #
      # @example
      #   # bad
      #   if condition
      #     do_x
      #     do_z
      #   else
      #     do_y
      #     do_z
      #   end
      #
      #   # good
      #   if condition
      #     do_x
      #   else
      #     do_y
      #   end
      #   do_z
      #
      #   # bad
      #   if condition
      #     do_z
      #     do_x
      #   else
      #     do_z
      #     do_y
      #   end
      #
      #   # good
      #   do_z
      #   if condition
      #     do_x
      #   else
      #     do_y
      #   end
      #
      #   # bad
      #   case foo
      #   when 1
      #     do_x
      #   when 2
      #     do_x
      #   else
      #     do_x
      #   end
      #
      #   # good
      #   case foo
      #   when 1
      #     do_x
      #     do_y
      #   when 2
      #     # nothing
      #   else
      #     do_x
      #     do_z
      #   end
      #
      #   # bad
      #   case foo
      #   in 1
      #     do_x
      #   in 2
      #     do_x
      #   else
      #     do_x
      #   end
      #
      #   # good
      #   case foo
      #   in 1
      #     do_x
      #     do_y
      #   in 2
      #     # nothing
      #   else
      #     do_x
      #     do_z
      #   end
      class IdenticalConditionalBranches < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Move `%<source>s` out of the conditional.'

        def on_if(node)
          return if node.elsif?

          branches = expand_elses(node.else_branch).unshift(node.if_branch)
          check_branches(node, branches)
        end

        def on_case(node)
          return unless node.else? && node.else_branch

          branches = node.when_branches.map(&:body).push(node.else_branch)
          check_branches(node, branches)
        end

        def on_case_match(node)
          return unless node.else? && node.else_branch

          branches = node.in_pattern_branches.map(&:body).push(node.else_branch)
          check_branches(node, branches)
        end

        private

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        def check_branches(node, branches)
          # return if any branch is empty. An empty branch can be an `if`
          # without an `else` or a branch that contains only comments.
          return if branches.any?(&:nil?)

          tails = branches.map { |branch| tail(branch) }
          check_expressions(node, tails, :after_condition) if duplicated_expressions?(node, tails)

          return if last_child_of_parent?(node) &&
                    branches.any? { |branch| single_child_branch?(branch) }

          heads = branches.map { |branch| head(branch) }

          return unless duplicated_expressions?(node, heads)

          condition_variable = assignable_condition_value(node)

          head = heads.first
          if head.respond_to?(:assignment?) && head.assignment?
            # The `send` node is used instead of the `indexasgn` node, so `name` cannot be used.
            # https://github.com/rubocop/rubocop-ast/blob/v1.29.0/lib/rubocop/ast/node/indexasgn_node.rb
            #
            # FIXME: It would be better to update `RuboCop::AST::OpAsgnNode` or its subclasses to
            # handle `self.foo ||= value` as a solution, instead of using `head.node_parts[0].to_s`.
            assigned_value = head.send_type? ? head.receiver.source : head.node_parts[0].to_s

            return if condition_variable == assigned_value
          end

          check_expressions(node, heads, :before_condition)
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

        def duplicated_expressions?(node, expressions)
          unique_expressions = expressions.uniq
          return false unless expressions.size >= 1 && unique_expressions.one?

          unique_expression = unique_expressions.first
          return true unless unique_expression&.assignment?

          lhs = unique_expression.child_nodes.first
          node.condition.child_nodes.none? { |n| n.source == lhs.source if n.variable? }
        end

        def assignable_condition_value(node)
          if node.condition.call_type?
            (receiver = node.condition.receiver) ? receiver.source : node.condition.source
          elsif node.condition.variable?
            node.condition.source
          end
        end

        # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
        def check_expressions(node, expressions, insert_position)
          return if expressions.any?(&:nil?)

          inserted_expression = false

          expressions.each do |expression|
            add_offense(expression) do |corrector|
              next if node.if_type? && (node.ternary? || node.then?)

              range = range_by_whole_lines(expression.source_range, include_final_newline: true)
              corrector.remove(range)
              next if inserted_expression

              if node.parent&.assignment?
                correct_assignment(corrector, node, expression, insert_position)
              else
                correct_no_assignment(corrector, node, expression, insert_position)
              end

              inserted_expression = true
            end
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

        def correct_assignment(corrector, node, expression, insert_position)
          if insert_position == :after_condition
            assignment = node.parent.source_range.with(end_pos: node.source_range.begin_pos)
            corrector.remove(assignment)
            corrector.insert_after(node, "\n#{assignment.source}#{expression.source}")
          else
            corrector.insert_before(node.parent, "#{expression.source}\n")
          end
        end

        def correct_no_assignment(corrector, node, expression, insert_position)
          if insert_position == :after_condition
            corrector.insert_after(node, "\n#{expression.source}")
          else
            corrector.insert_before(node, "#{expression.source}\n")
          end
        end

        def last_child_of_parent?(node)
          return true unless (parent = node.parent)

          parent.child_nodes.last == node
        end

        def single_child_branch?(branch_node)
          !branch_node.begin_type? || branch_node.children.size == 1
        end

        def message(node)
          format(MSG, source: node.source)
        end

        # `elsif` branches show up in the if node as nested `else` branches. We
        # need to recursively iterate over all `else` branches.
        def expand_elses(branch)
          if branch.nil?
            [nil]
          elsif branch.if_type?
            _condition, elsif_branch, else_branch = *branch
            expand_elses(else_branch).unshift(elsif_branch)
          else
            [branch]
          end
        end

        def tail(node)
          node.begin_type? ? node.children.last : node
        end

        def head(node)
          node.begin_type? ? node.children.first : node
        end
      end
    end
  end
end
