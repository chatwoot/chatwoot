# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the presence of a `return` inside a `begin..end` block
      # in assignment contexts.
      # In this situation, the `return` will result in an exit from the current
      # method, possibly leading to unexpected behavior.
      #
      # @example
      #
      #   # bad
      #   @some_variable ||= begin
      #     return some_value if some_condition_is_met
      #
      #     do_something
      #   end
      #
      #   # good
      #   @some_variable ||= begin
      #     if some_condition_is_met
      #       some_value
      #     else
      #       do_something
      #     end
      #   end
      #
      #   # good
      #   some_variable = if some_condition_is_met
      #                     return if another_condition_is_met
      #
      #                     some_value
      #                   else
      #                     do_something
      #                   end
      #
      class NoReturnInBeginEndBlocks < Base
        MSG = 'Do not `return` in `begin..end` blocks in assignment contexts.'

        def on_lvasgn(node)
          node.each_node(:kwbegin) do |kwbegin_node|
            kwbegin_node.each_node(:return) do |return_node|
              add_offense(return_node)
            end
          end
        end
        alias on_or_asgn on_lvasgn
        alias on_op_asgn on_lvasgn
      end
    end
  end
end
