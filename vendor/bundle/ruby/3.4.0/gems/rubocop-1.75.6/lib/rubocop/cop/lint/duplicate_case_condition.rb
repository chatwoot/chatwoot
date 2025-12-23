# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks that there are no repeated conditions
      # used in case 'when' expressions.
      #
      # @example
      #
      #   # bad
      #   case x
      #   when 'first'
      #     do_something
      #   when 'first'
      #     do_something_else
      #   end
      #
      #   # good
      #   case x
      #   when 'first'
      #     do_something
      #   when 'second'
      #     do_something_else
      #   end
      class DuplicateCaseCondition < Base
        MSG = 'Duplicate `when` condition detected.'

        def on_case(case_node)
          case_node.when_branches.each_with_object(Set.new) do |when_node, previous|
            when_node.conditions.each do |condition|
              add_offense(condition) unless previous.add?(condition)
            end
          end
        end
      end
    end
  end
end
