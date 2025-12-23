# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Certain numeric operations have a constant result, usually 0 or 1.
      # Multiplying a number by 0 will always return 0.
      # Dividing a number by itself or raising it to the power of 0 will always return 1.
      # As such, they can be replaced with that result.
      # These are probably leftover from debugging, or are mistakes.
      # Other numeric operations that are similarly leftover from debugging or mistakes
      # are handled by `Lint/UselessNumericOperation`.
      #
      # NOTE: This cop doesn't detect offenses for the `-` and `%` operator because it
      # can't determine the type of `x`. If `x` is an `Array` or `String`, it doesn't perform
      # a numeric operation.
      #
      # @example
      #
      #   # bad
      #   x * 0
      #
      #   # good
      #   0
      #
      #   # bad
      #   x *= 0
      #
      #   # good
      #   x = 0
      #
      #   # bad
      #   x / x
      #   x ** 0
      #
      #   # good
      #   1
      #
      #   # bad
      #   x /= x
      #   x **= 0
      #
      #   # good
      #   x = 1
      #
      class NumericOperationWithConstantResult < Base
        extend AutoCorrector
        MSG = 'Numeric operation with a constant result detected.'
        RESTRICT_ON_SEND = %i[* / **].freeze

        # @!method operation_with_constant_result?(node)
        def_node_matcher :operation_with_constant_result?,
                         '(call (call nil? $_lhs) $_operation ({int | call nil?} $_rhs))'

        # @!method abbreviated_assignment_with_constant_result?(node)
        def_node_matcher :abbreviated_assignment_with_constant_result?,
                         '(op-asgn (lvasgn $_lhs) $_operation ({int lvar} $_rhs))'

        def on_send(node)
          return unless (lhs, operation, rhs = operation_with_constant_result?(node))
          return unless (result = constant_result?(lhs, operation, rhs))

          add_offense(node) do |corrector|
            corrector.replace(node, result.to_s)
          end
        end
        alias on_csend on_send

        def on_op_asgn(node)
          return unless (lhs, operation, rhs = abbreviated_assignment_with_constant_result?(node))
          return unless (result = constant_result?(lhs, operation, rhs))

          add_offense(node) do |corrector|
            corrector.replace(node, "#{lhs} = #{result}")
          end
        end

        private

        def constant_result?(lhs, operation, rhs)
          if rhs.to_s == '0'
            return 0 if operation == :*
            return 1 if operation == :**
          elsif rhs == lhs
            return 1 if operation == :/
          end
          # If we weren't able to find any matches, return false so we can bail out.
          false
        end
      end
    end
  end
end
