# frozen_string_literal: true

module RuboCop
  module Cop
    # Classes that include this module just implement functions for working
    # with symbol nodes.
    module SymbolHelp
      def hash_key?(node)
        node.parent&.pair_type? && node == node.parent.child_nodes.first
      end
    end
  end
end
