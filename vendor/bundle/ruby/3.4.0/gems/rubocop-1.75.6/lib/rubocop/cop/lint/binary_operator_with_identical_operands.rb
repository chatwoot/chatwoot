# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for places where binary operator has identical operands.
      #
      # It covers comparison operators: `==`, `===`, `=~`, `>`, `>=`, `<`, ``<=``;
      # bitwise operators: `|`, `^`, `&`;
      # boolean operators: `&&`, `||`
      # and "spaceship" operator - ``<=>``.
      #
      # Simple arithmetic operations are allowed by this cop: `+`, `*`, `**`, `<<` and `>>`.
      # Although these can be rewritten in a different way, it should not be necessary to
      # do so. Operations such as `-` or `/` where the result will always be the same
      # (`x - x` will always be 0; `x / x` will always be 1) are offenses, but these
      # are covered by `Lint/NumericOperationWithConstantResult` instead.
      #
      # @safety
      #   This cop is unsafe as it does not consider side effects when calling methods
      #   and thus can generate false positives, for example:
      #
      #   [source,ruby]
      #   ----
      #   if wr.take_char == '\0' && wr.take_char == '\0'
      #     # ...
      #   end
      #   ----
      #
      # @example
      #   # bad
      #   x.top >= x.top
      #
      #   if a.x != 0 && a.x != 0
      #     do_something
      #   end
      #
      #   def child?
      #     left_child || left_child
      #   end
      #
      #   # good
      #   x + x
      #   1 << 1
      #
      class BinaryOperatorWithIdenticalOperands < Base
        MSG = 'Binary operator `%<op>s` has identical operands.'
        RESTRICT_ON_SEND = %i[== != === <=> =~ && || > >= < <= | ^].freeze

        def on_send(node)
          return unless node.binary_operation?
          return unless node.receiver == node.first_argument

          add_offense(node, message: format(MSG, op: node.method_name))
        end

        def on_and(node)
          return unless node.lhs == node.rhs

          add_offense(node, message: format(MSG, op: node.operator))
        end
        alias on_or on_and
      end
    end
  end
end
