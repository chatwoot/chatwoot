# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the use of local variable names from an outer scope
      # in block arguments or block-local variables. This mirrors the warning
      # given by `ruby -cw` prior to Ruby 2.6:
      # "shadowing outer local variable - foo".
      #
      # NOTE: Shadowing of variables in block passed to `Ractor.new` is allowed
      # because `Ractor` should not access outer variables.
      # eg. following style is encouraged:
      #
      # [source,ruby]
      # ----
      # worker_id, pipe = env
      # Ractor.new(worker_id, pipe) do |worker_id, pipe|
      # end
      # ----
      #
      # @example
      #
      #   # bad
      #   def some_method
      #     foo = 1
      #
      #     2.times do |foo| # shadowing outer `foo`
      #       do_something(foo)
      #     end
      #   end
      #
      #   # good
      #   def some_method
      #     foo = 1
      #
      #     2.times do |bar|
      #       do_something(bar)
      #     end
      #   end
      class ShadowingOuterLocalVariable < Base
        MSG = 'Shadowing outer local variable - `%<variable>s`.'

        # @!method ractor_block?(node)
        def_node_matcher :ractor_block?, <<~PATTERN
          (block (send (const nil? :Ractor) :new ...) ...)
        PATTERN

        def self.joining_forces
          VariableForce
        end

        def before_declaring_variable(variable, variable_table)
          return if variable.should_be_unused?
          return if ractor_block?(variable.scope.node)

          outer_local_variable = variable_table.find_variable(variable.name)
          return unless outer_local_variable
          return if variable_used_in_declaration_of_outer?(variable, outer_local_variable)
          return if same_conditions_node_different_branch?(variable, outer_local_variable)

          message = format(MSG, variable: variable.name)
          add_offense(variable.declaration_node, message: message)
        end

        private

        def variable_used_in_declaration_of_outer?(variable, outer_local_variable)
          variable.scope.node.each_ancestor.any?(outer_local_variable.declaration_node)
        end

        def same_conditions_node_different_branch?(variable, outer_local_variable)
          variable_node = variable_node(variable)
          return false unless node_or_its_ascendant_conditional?(variable_node)

          outer_local_variable_node =
            find_conditional_node_from_ascendant(outer_local_variable.declaration_node)
          return false unless outer_local_variable_node
          return false unless outer_local_variable_node.conditional?
          return true if variable_node == outer_local_variable_node

          outer_local_variable_node.if_type? &&
            variable_node == outer_local_variable_node.else_branch
        end

        def variable_node(variable)
          parent_node = variable.scope.node.parent

          if parent_node.when_type?
            parent_node.parent
          else
            parent_node
          end
        end

        def find_conditional_node_from_ascendant(node)
          return unless (parent = node.parent)
          return parent if parent.conditional?

          find_conditional_node_from_ascendant(parent)
        end

        def node_or_its_ascendant_conditional?(node)
          return true if node.conditional?

          !!find_conditional_node_from_ascendant(node)
        end
      end
    end
  end
end
