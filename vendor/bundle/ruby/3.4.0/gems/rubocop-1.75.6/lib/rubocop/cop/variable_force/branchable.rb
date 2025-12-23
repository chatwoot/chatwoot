# frozen_string_literal: true

module RuboCop
  module Cop
    class VariableForce
      # Mix-in module for classes which own a node and need branch information
      # of the node. The user classes must implement #node and #scope.
      module Branchable
        def branch
          return @branch if instance_variable_defined?(:@branch)

          @branch = Branch.of(node, scope: scope)
        end

        def run_exclusively_with?(other)
          return false if !branch || !other.branch

          branch.exclusive_with?(other.branch)
        end
      end
    end
  end
end
