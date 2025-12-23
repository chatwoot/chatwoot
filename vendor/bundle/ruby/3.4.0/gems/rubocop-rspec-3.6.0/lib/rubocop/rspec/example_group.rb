# frozen_string_literal: true

module RuboCop
  module RSpec
    # Wrapper for RSpec example groups
    class ExampleGroup < Concept
      # @!method scope_change?(node)
      #
      #   Detect if the node is an example group or shared example
      #
      #   Selectors which indicate that we should stop searching
      #
      def_node_matcher :scope_change?, <<~PATTERN
        (block {
          (send #rspec? {#SharedGroups.all #ExampleGroups.all} ...)
          (send nil? #Includes.all ...)
        } ...)
      PATTERN

      def lets
        find_all_in_scope(node, :let?)
      end

      def subjects
        find_all_in_scope(node, :subject?)
      end

      def examples
        find_all_in_scope(node, :example?).map do |node|
          Example.new(node)
        end
      end

      def hooks
        find_all_in_scope(node, :hook?).map do |node|
          Hook.new(node)
        end
      end

      private

      # Recursively search for predicate within the current scope
      #
      # Searches node and halts when a scope change is detected
      #
      # @param node [RuboCop::AST::Node] node to recursively search
      # @param predicate [Symbol] method to call with node as argument
      #
      # @return [Array<RuboCop::AST::Node>] discovered nodes
      def find_all_in_scope(node, predicate)
        node.each_child_node.flat_map do |child|
          find_all(child, predicate)
        end
      end

      def find_all(node, predicate)
        if public_send(predicate, node)
          [node]
        elsif scope_change?(node) || example?(node)
          []
        else
          find_all_in_scope(node, predicate)
        end
      end
    end
  end
end
