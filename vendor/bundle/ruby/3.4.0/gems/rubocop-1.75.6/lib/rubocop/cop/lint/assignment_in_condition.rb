# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for assignments in the conditions of
      # if/while/until.
      #
      # `AllowSafeAssignment` option for safe assignment.
      # By safe assignment we mean putting parentheses around
      # an assignment to indicate "I know I'm using an assignment
      # as a condition. It's not a mistake."
      #
      # @safety
      #   This cop's autocorrection is unsafe because it assumes that
      #   the author meant to use an assignment result as a condition.
      #
      # @example
      #   # bad
      #   if some_var = value
      #     do_something
      #   end
      #
      #   # good
      #   if some_var == value
      #     do_something
      #   end
      #
      # @example AllowSafeAssignment: true (default)
      #   # good
      #   if (some_var = value)
      #     do_something
      #   end
      #
      # @example AllowSafeAssignment: false
      #   # bad
      #   if (some_var = value)
      #     do_something
      #   end
      #
      class AssignmentInCondition < Base
        extend AutoCorrector

        include SafeAssignment

        MSG_WITH_SAFE_ASSIGNMENT_ALLOWED =
          'Use `==` if you meant to do a comparison or wrap the expression ' \
          'in parentheses to indicate you meant to assign in a ' \
          'condition.'
        MSG_WITHOUT_SAFE_ASSIGNMENT_ALLOWED =
          'Use `==` if you meant to do a comparison or move the assignment ' \
          'up out of the condition.'
        ASGN_TYPES = [:begin, *AST::Node::EQUALS_ASSIGNMENTS, :send, :csend].freeze

        def on_if(node)
          traverse_node(node.condition) do |asgn_node|
            next :skip_children if skip_children?(asgn_node)
            next if allowed_construct?(asgn_node)

            add_offense(asgn_node.loc.operator) do |corrector|
              next unless safe_assignment_allowed?

              corrector.wrap(asgn_node, '(', ')')
            end
          end
        end
        alias on_while on_if
        alias on_until on_if

        private

        def message(_node)
          if safe_assignment_allowed?
            MSG_WITH_SAFE_ASSIGNMENT_ALLOWED
          else
            MSG_WITHOUT_SAFE_ASSIGNMENT_ALLOWED
          end
        end

        def allowed_construct?(asgn_node)
          asgn_node.begin_type? || conditional_assignment?(asgn_node)
        end

        def conditional_assignment?(asgn_node)
          !asgn_node.loc.operator
        end

        def skip_children?(asgn_node)
          (asgn_node.call_type? && !asgn_node.assignment_method?) ||
            empty_condition?(asgn_node) ||
            (safe_assignment_allowed? && safe_assignment?(asgn_node))
        end

        def traverse_node(node, &block)
          # if the node is a block, any assignments are irrelevant
          return if node.any_block_type?

          result = yield node if ASGN_TYPES.include?(node.type)

          return if result == :skip_children

          node.each_child_node { |child| traverse_node(child, &block) }
        end
      end
    end
  end
end
