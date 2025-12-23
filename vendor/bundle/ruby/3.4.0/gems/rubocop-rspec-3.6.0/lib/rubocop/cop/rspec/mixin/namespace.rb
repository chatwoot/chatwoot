# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Helps to find namespace of the node.
      module Namespace
        private

        # @param node [RuboCop::AST::Node]
        # @return [Array<String>]
        # @example
        #   namespace(node) # => ['A', 'B', 'C']
        def namespace(node)
          node
            .each_ancestor(:class, :module)
            .reverse_each
            .flat_map { |ancestor| ancestor.defined_module_name.split('::') }
        end
      end
    end
  end
end
