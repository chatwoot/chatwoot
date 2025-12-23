# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of the keyword `not` instead of `!`.
      #
      # @example
      #
      #   # bad - parentheses are required because of op precedence
      #   x = (not something)
      #
      #   # good
      #   x = !something
      #
      class Not < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `!` instead of `not`.'
        RESTRICT_ON_SEND = %i[!].freeze

        OPPOSITE_METHODS = {
          :== => :!=,
          :!= => :==,
          :<= => :>,
          :> => :<=,
          :< => :>=,
          :>= => :<
        }.freeze

        def on_send(node)
          return unless node.prefix_not?

          add_offense(node.loc.selector) do |corrector|
            range = range_with_surrounding_space(node.loc.selector, side: :right)

            if opposite_method?(node.receiver)
              correct_opposite_method(corrector, range, node.receiver)
            elsif requires_parens?(node.receiver)
              correct_with_parens(corrector, range, node)
            else
              correct_without_parens(corrector, range)
            end
          end
        end

        private

        def opposite_method?(child)
          child.send_type? && OPPOSITE_METHODS.key?(child.method_name)
        end

        def requires_parens?(child)
          child.operator_keyword? ||
            (child.send_type? && child.binary_operation?) ||
            (child.if_type? && child.ternary?)
        end

        def correct_opposite_method(corrector, range, child)
          corrector.remove(range)
          corrector.replace(child.loc.selector, OPPOSITE_METHODS[child.method_name].to_s)
        end

        def correct_with_parens(corrector, range, node)
          corrector.replace(range, '!(')
          corrector.insert_after(node, ')')
        end

        def correct_without_parens(corrector, range)
          corrector.replace(range, '!')
        end
      end
    end
  end
end
