# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Enforces the use the shorthand for self-assignment.
      #
      # @example
      #
      #   # bad
      #   x = x + 1
      #
      #   # good
      #   x += 1
      class SelfAssignment < Base
        extend AutoCorrector

        MSG = 'Use self-assignment shorthand `%<method>s=`.'
        OPS = %i[+ - * ** / % ^ << >> | &].freeze

        def self.autocorrect_incompatible_with
          [Layout::SpaceAroundOperators]
        end

        def on_lvasgn(node)
          check(node, :lvar)
        end

        def on_ivasgn(node)
          check(node, :ivar)
        end

        def on_cvasgn(node)
          check(node, :cvar)
        end

        private

        def check(node, var_type)
          return unless (rhs = node.expression)

          if rhs.send_type? && rhs.arguments.one?
            check_send_node(node, rhs, node.name, var_type)
          elsif rhs.operator_keyword?
            check_boolean_node(node, rhs, node.name, var_type)
          end
        end

        def check_send_node(node, rhs, var_name, var_type)
          return unless OPS.include?(rhs.method_name)

          target_node = s(var_type, var_name)
          return unless rhs.receiver == target_node

          add_offense(node, message: format(MSG, method: rhs.method_name)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def check_boolean_node(node, rhs, var_name, var_type)
          target_node = s(var_type, var_name)
          return unless rhs.lhs == target_node

          operator = rhs.loc.operator.source
          add_offense(node, message: format(MSG, method: operator)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        def autocorrect(corrector, node)
          rhs = node.expression

          if rhs.send_type?
            autocorrect_send_node(corrector, node, rhs)
          elsif rhs.operator_keyword?
            autocorrect_boolean_node(corrector, node, rhs)
          end
        end

        def autocorrect_send_node(corrector, node, rhs)
          apply_autocorrect(corrector, node, rhs, rhs.method_name, rhs.first_argument)
        end

        def autocorrect_boolean_node(corrector, node, rhs)
          apply_autocorrect(corrector, node, rhs, rhs.loc.operator.source, rhs.rhs)
        end

        def apply_autocorrect(corrector, node, rhs, operator, new_rhs)
          corrector.insert_before(node.loc.operator, operator)
          corrector.replace(rhs, new_rhs.source)
        end
      end
    end
  end
end
