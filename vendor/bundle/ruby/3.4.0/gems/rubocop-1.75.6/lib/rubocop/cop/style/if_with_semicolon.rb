# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of semicolon in if statements.
      #
      # @example
      #
      #   # bad
      #   result = if some_condition; something else another_thing end
      #
      #   # good
      #   result = some_condition ? something : another_thing
      #
      class IfWithSemicolon < Base
        include OnNormalIfUnless
        extend AutoCorrector

        MSG_IF_ELSE = 'Do not use `if %<expr>s;` - use `if/else` instead.'
        MSG_NEWLINE = 'Do not use `if %<expr>s;` - use a newline instead.'
        MSG_TERNARY = 'Do not use `if %<expr>s;` - use a ternary operator instead.'

        def on_normal_if_unless(node)
          return if node.parent&.if_type?
          return if part_of_ignored_node?(node)

          beginning = node.loc.begin
          return unless beginning&.is?(';')

          message = message(node)

          add_offense(node, message: message) do |corrector|
            autocorrect(corrector, node)
          end

          ignore_node(node)
        end

        private

        def message(node)
          template = if require_newline?(node)
                       MSG_NEWLINE
                     elsif node.else_branch&.type?(:if, :begin) ||
                           use_masgn_or_block_in_branches?(node)
                       MSG_IF_ELSE
                     else
                       MSG_TERNARY
                     end

          format(template, expr: node.condition.source)
        end

        def autocorrect(corrector, node)
          if require_newline?(node) || use_masgn_or_block_in_branches?(node)
            corrector.replace(node.loc.begin, "\n")
          else
            corrector.replace(node, replacement(node))
          end
        end

        def require_newline?(node)
          node.branches.compact.any?(&:begin_type?) || use_return_with_argument?(node)
        end

        def use_masgn_or_block_in_branches?(node)
          node.branches.compact.any? do |branch|
            branch.type?(:masgn, :any_block)
          end
        end

        def use_return_with_argument?(node)
          node.if_branch&.return_type? && node.if_branch&.arguments&.any?
        end

        def replacement(node)
          return correct_elsif(node) if node.else_branch&.if_type?

          then_code = node.if_branch ? build_expression(node.if_branch) : 'nil'
          else_code = node.else_branch ? build_expression(node.else_branch) : 'nil'

          "#{node.condition.source} ? #{then_code} : #{else_code}"
        end

        def correct_elsif(node)
          <<~RUBY.chop
            if #{node.condition.source}
              #{node.if_branch&.source}
            #{build_else_branch(node.else_branch).chop}
            end
          RUBY
        end

        def build_expression(expr)
          return expr.source unless require_argument_parentheses?(expr)

          method = expr.source_range.begin.join(expr.loc.selector.end)
          arguments = expr.first_argument.source_range.begin.join(expr.source_range.end)

          "#{method.source}(#{arguments.source})"
        end

        def build_else_branch(second_condition)
          result = <<~RUBY
            elsif #{second_condition.condition.source}
              #{second_condition.if_branch&.source}
          RUBY

          if second_condition.else_branch
            result += if second_condition.else_branch.if_type?
                        build_else_branch(second_condition.else_branch)
                      else
                        <<~RUBY
                          else
                            #{second_condition.else_branch.source}
                        RUBY
                      end
          end

          result
        end

        def require_argument_parentheses?(node)
          return false if !node.call_type? || node.arithmetic_operation?

          !node.parenthesized? && node.arguments.any? && !node.method?(:[]) && !node.method?(:[]=)
        end
      end
    end
  end
end
