# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks that there are no repeated conditions used in if 'elsif'.
      #
      # @example
      #   # bad
      #   if x == 1
      #     do_something
      #   elsif x == 1
      #     do_something_else
      #   end
      #
      #   # good
      #   if x == 1
      #     do_something
      #   elsif x == 2
      #     do_something_else
      #   end
      #
      class DuplicateElsifCondition < Base
        MSG = 'Duplicate `elsif` condition detected.'

        def on_if(node)
          previous = []
          while node.if? || node.elsif?
            condition = node.condition
            add_offense(condition) if previous.include?(condition)
            previous << condition
            node = node.else_branch
            break unless node&.if_type?
          end
        end
      end
    end
  end
end
