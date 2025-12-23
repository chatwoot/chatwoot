# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      class MethodCallWithArgsParentheses
        # Style require_parentheses
        module RequireParentheses
          REQUIRE_MSG = 'Use parentheses for method calls with arguments.'
          private_constant :REQUIRE_MSG

          private

          def require_parentheses(node)
            return if allowed_method_name?(node.method_name)
            return if matches_allowed_pattern?(node.method_name)
            return if eligible_for_parentheses_omission?(node)
            return unless node.arguments? && !node.parenthesized?

            add_offense(node, message: REQUIRE_MSG) do |corrector|
              corrector.replace(args_begin(node), '(')

              corrector.insert_after(args_end(node), ')') unless args_parenthesized?(node)
            end
          end

          def allowed_method_name?(name)
            allowed_method?(name) || matches_allowed_pattern?(name)
          end

          def eligible_for_parentheses_omission?(node)
            node.operator_method? || node.setter_method? || ignored_macro?(node)
          end

          def included_macros_list
            cop_config.fetch('IncludedMacros', []).map(&:to_sym)
          end

          def ignored_macro?(node)
            cop_config['IgnoreMacros'] &&
              node.macro? &&
              !included_macros_list.include?(node.method_name)
          end
        end
      end
    end
  end
end
