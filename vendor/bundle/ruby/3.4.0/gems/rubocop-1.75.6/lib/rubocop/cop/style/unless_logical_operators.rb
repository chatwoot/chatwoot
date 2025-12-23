# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the use of logical operators in an `unless` condition.
      # It discourages such code, as the condition becomes more difficult
      # to read and understand.
      #
      # This cop supports two styles:
      #
      # - `forbid_mixed_logical_operators` (default)
      # - `forbid_logical_operators`
      #
      # `forbid_mixed_logical_operators` style forbids the use of more than one type
      # of logical operators. This makes the `unless` condition easier to read
      # because either all conditions need to be met or any condition need to be met
      # in order for the expression to be truthy or falsey.
      #
      # `forbid_logical_operators` style forbids any use of logical operator.
      # This makes it even more easy to read the `unless` condition as
      # there is only one condition in the expression.
      #
      # @example EnforcedStyle: forbid_mixed_logical_operators (default)
      #   # bad
      #   return unless a || b && c
      #   return unless a && b || c
      #   return unless a && b and c
      #   return unless a || b or c
      #   return unless a && b or c
      #   return unless a || b and c
      #
      #   # good
      #   return unless a && b && c
      #   return unless a || b || c
      #   return unless a and b and c
      #   return unless a or b or c
      #   return unless a?
      #
      # @example EnforcedStyle: forbid_logical_operators
      #   # bad
      #   return unless a || b
      #   return unless a && b
      #   return unless a or b
      #   return unless a and b
      #
      #   # good
      #   return unless a
      #   return unless a?
      class UnlessLogicalOperators < Base
        include ConfigurableEnforcedStyle

        FORBID_MIXED_LOGICAL_OPERATORS = 'Do not use mixed logical operators in an `unless`.'
        FORBID_LOGICAL_OPERATORS = 'Do not use any logical operator in an `unless`.'

        # @!method or_with_and?(node)
        def_node_matcher :or_with_and?, <<~PATTERN
          (if (or <`and ...> ) ...)
        PATTERN

        # @!method and_with_or?(node)
        def_node_matcher :and_with_or?, <<~PATTERN
          (if (and <`or ...> ) ...)
        PATTERN

        # @!method logical_operator?(node)
        def_node_matcher :logical_operator?, <<~PATTERN
          (if ({and or} ... ) ...)
        PATTERN

        def on_if(node)
          return unless node.unless?

          if style == :forbid_mixed_logical_operators && mixed_logical_operator?(node)
            add_offense(node, message: FORBID_MIXED_LOGICAL_OPERATORS)
          elsif style == :forbid_logical_operators && logical_operator?(node)
            add_offense(node, message: FORBID_LOGICAL_OPERATORS)
          end
        end

        private

        def mixed_logical_operator?(node)
          or_with_and?(node) ||
            and_with_or?(node) ||
            mixed_precedence_and?(node) ||
            mixed_precedence_or?(node)
        end

        def mixed_precedence_and?(node)
          and_sources = node.condition.each_descendant(:and).map(&:operator)
          and_sources << node.condition.operator if node.condition.and_type?

          !(and_sources.all?('&&') || and_sources.all?('and'))
        end

        def mixed_precedence_or?(node)
          or_sources = node.condition.each_descendant(:or).map(&:operator)
          or_sources << node.condition.operator if node.condition.or_type?

          !(or_sources.all?('||') || or_sources.all?('or'))
        end
      end
    end
  end
end
