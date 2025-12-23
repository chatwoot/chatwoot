# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      class NodePatternGroups
        # AST Processor for NodePattern ASTs, for use with `InternalAffairs/NodePatternGroups`.
        #
        # Looks for sequences and subsequences where the first item is a `node_type` node,
        # and converts them to `node_sequence` nodes (not a true `Rubocop::AST::NodePattern`
        # node type).
        #
        # The resulting AST will be walked by `InternalAffairs::NodePatternGroups::ASTWalker`
        # in order to find node types in a `union` node that can be rewritten as a node group.
        #
        # NOTE: The `on_*` methods in this class relate not to the normal node types but
        # rather to the Node Pattern node types. Not every node type is handled.
        #
        class ASTProcessor
          include ::AST::Processor::Mixin

          def handler_missing(node)
            node.updated(nil, process_children(node))
          end

          # Look for `sequence` and `subsequence` nodes that contain a `node_type` node as
          # their first child. These are rewritten as `node_sequence` nodes so that it is
          # possible to compare nodes while looking for replacement candidates for node groups.
          # This is necessary so that extended patterns can be matched and replaced.
          # ie. `{(send _ :foo ...) (csend _ :foo ...)}` can become `(call _ :foo ...)`
          def on_sequence(node)
            first_child = node.child

            if first_child.type == :node_type
              children = [first_child.child, *process_children(node, 1..)]

              # The `node_sequence` node contains the `node_type` symbol as its first child,
              # followed by all the other nodes contained in the `sequence` node.
              # The location is copied from the sequence, so that the entire sequence can
              # eventually be corrected in the cop.
              n(:node_sequence, children, location: node.location)
            else
              node.updated(nil, process_children(node))
            end
          end
          alias on_subsequence on_sequence

          private

          def n(type, children = [], properties = {})
            NodePattern::Node.new(type, children, properties)
          end

          def process_children(node, range = 0..-1)
            node.children[range].map do |child|
              child.is_a?(::AST::Node) ? process(child) : child
            end
          end
        end
      end
    end
  end
end
