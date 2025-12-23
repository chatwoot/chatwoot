# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for every useless assignment to local variable in every
      # scope.
      # The basic idea for this cop was from the warning of `ruby -cw`:
      #
      # [source,console]
      # ----
      # assigned but unused variable - foo
      # ----
      #
      # Currently this cop has advanced logic that detects unreferenced
      # reassignments and properly handles varied cases such as branch, loop,
      # rescue, ensure, etc.
      #
      # This cop's autocorrection avoids cases like `a ||= 1` because removing assignment from
      # operator assignment can cause `NameError` if this assignment has been used to declare
      # a local variable. For example, replacing `a ||= 1` with `a || 1` may cause
      # "undefined local variable or method `a' for main:Object (NameError)".
      #
      # NOTE: Given the assignment `foo = 1, bar = 2`, removing unused variables
      # can lead to a syntax error, so this case is not autocorrected.
      #
      # @example
      #
      #   # bad
      #   def some_method
      #     some_var = 1
      #     do_something
      #   end
      #
      #   # good
      #   def some_method
      #     some_var = 1
      #     do_something(some_var)
      #   end
      class UselessAssignment < Base
        extend AutoCorrector

        include RangeHelp

        MSG = 'Useless assignment to variable - `%<variable>s`.'

        def self.joining_forces
          VariableForce
        end

        def after_leaving_scope(scope, _variable_table)
          scope.variables.each_value { |variable| check_for_unused_assignments(variable) }
        end

        # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def check_for_unused_assignments(variable)
          return if variable.should_be_unused?

          variable.assignments.reverse_each do |assignment|
            assignment_node = assignment.node
            next if assignment.used? || part_of_ignored_node?(assignment_node)

            message = message_for_useless_assignment(assignment)
            range = offense_range(assignment)

            add_offense(range, message: message) do |corrector|
              # In cases like `x = 1, y = 2`, where removing a variable would cause a syntax error,
              # and where changing `x ||= 1` to `x = 1` would cause `NameError`,
              # the autocorrect will be skipped, even if the variable is unused.
              if sequential_assignment?(assignment_node) || assignment_node.parent&.or_asgn_type?
                next
              end

              autocorrect(corrector, assignment)
            end

            ignore_node(assignment_node) if chained_assignment?(assignment_node)
          end
        end
        # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

        def message_for_useless_assignment(assignment)
          variable = assignment.variable

          format(MSG, variable: variable.name) + message_specification(assignment, variable).to_s
        end

        def offense_range(assignment)
          if assignment.regexp_named_capture?
            assignment.node.children.first.source_range
          else
            assignment.node.loc.name
          end
        end

        def sequential_assignment?(node)
          if node.lvasgn_type? && node.expression&.array_type? &&
             node.each_descendant.any?(&:assignment?)
            return true
          end
          return false unless node.parent

          sequential_assignment?(node.parent)
        end

        def chained_assignment?(node)
          return true if node.lvasgn_type? && node.expression&.send_type?

          node.respond_to?(:expression) && node.expression&.lvasgn_type?
        end

        def message_specification(assignment, variable)
          if assignment.multiple_assignment?
            multiple_assignment_message(variable.name)
          elsif assignment.operator_assignment?
            operator_assignment_message(variable.scope, assignment)
          else
            similar_name_message(variable)
          end
        end

        def multiple_assignment_message(variable_name)
          " Use `_` or `_#{variable_name}` as a variable name to indicate " \
            "that it won't be used."
        end

        def operator_assignment_message(scope, assignment)
          return_value_node = return_value_node_of_scope(scope)
          return unless assignment.meta_assignment_node.equal?(return_value_node)

          " Use `#{assignment.operator.delete_suffix('=')}` instead of `#{assignment.operator}`."
        end

        def similar_name_message(variable)
          variable_like_names = collect_variable_like_names(variable.scope)
          similar_name = NameSimilarity.find_similar_name(variable.name, variable_like_names)
          " Did you mean `#{similar_name}`?" if similar_name
        end

        # TODO: More precise handling (rescue, ensure, nested begin, etc.)
        def return_value_node_of_scope(scope)
          body_node = scope.body_node

          if body_node.begin_type?
            body_node.children.last
          else
            body_node
          end
        end

        def collect_variable_like_names(scope)
          names = scope.each_node.with_object(Set.new) do |node, set|
            set << node.method_name if variable_like_method_invocation?(node)
          end

          variable_names = scope.variables.each_value.map(&:name)
          names.merge(variable_names)
        end

        def variable_like_method_invocation?(node)
          return false unless node.send_type?

          node.receiver.nil? && !node.arguments?
        end

        # rubocop:disable Metrics/AbcSize
        def autocorrect(corrector, assignment)
          if assignment.exception_assignment?
            remove_exception_assignment_part(corrector, assignment.node)
          elsif assignment.multiple_assignment? || assignment.rest_assignment? ||
                assignment.for_assignment?
            rename_variable_with_underscore(corrector, assignment.node)
          elsif assignment.operator_assignment?
            remove_trailing_character_from_operator(corrector, assignment.node)
          elsif assignment.regexp_named_capture?
            replace_named_capture_group_with_non_capturing_group(corrector, assignment.node,
                                                                 assignment.variable.name)
          else
            remove_local_variable_assignment_part(corrector, assignment.node)
          end
        end
        # rubocop:enable Metrics/AbcSize

        def remove_exception_assignment_part(corrector, node)
          corrector.remove(
            range_between(
              (node.parent.children.first&.source_range || node.parent.location.keyword).end_pos,
              node.source_range.end_pos
            )
          )
        end

        def rename_variable_with_underscore(corrector, node)
          corrector.replace(node, '_')
        end

        def remove_trailing_character_from_operator(corrector, node)
          corrector.remove(node.parent.location.operator.end.adjust(begin_pos: -1))
        end

        def replace_named_capture_group_with_non_capturing_group(corrector, node, variable_name)
          corrector.replace(
            node.children.first,
            node.children.first.source.sub(/\(\?<#{variable_name}>/, '(?:')
          )
        end

        def remove_local_variable_assignment_part(corrector, node)
          corrector.replace(node, node.expression.source)
        end
      end
    end
  end
end
