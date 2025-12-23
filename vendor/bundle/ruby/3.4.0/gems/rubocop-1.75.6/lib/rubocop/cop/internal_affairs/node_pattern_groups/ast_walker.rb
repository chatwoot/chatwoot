# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # rubocop:disable InternalAffairs/RedundantSourceRange -- node here is a `NodePattern::Node`
      class NodePatternGroups
        # Walks an AST that has been processed by `InternalAffairs::NodePatternGroups::Processor`
        # in order to find `node_type` and `node_sequence` nodes that can be replaced with a node
        # group in `InternalAffairs/NodePatternGroups`.
        #
        # Calling `ASTWalker#walk` sets `node_groups` with an array of `NodeGroup` structs
        # that contain metadata about nodes that can be replaced, including location data. That
        # metadata is used by the cop to register offenses and perform corrections.
        class ASTWalker
          # Struct to contain data about parts of a node pattern that can be replaced
          NodeGroup = Struct.new(
            :name,             # The name of the node group that will be inserted
            :union,            # The entire `union` node
            :node_types,       # An array of `node_type` nodes that will be removed
            :sequence?,        # The pattern matches a node type with given attributes
            :start_index,      # The index in the union of the first node type to remove
            :offense_range,    # The range to mark an offense on
            :ranges,           # Range of each element to remove, since they may not be adjacent
            :pipe,             # Is the union delimited by pipes?
            :other_elements?,  # Does the union have other elements other than those to remove?
            keyword_init: true
          )

          def initialize
            reset!
          end

          def reset!
            @node_groups = []
          end

          attr_reader :node_groups

          # Recursively walk the AST in a depth-first manner.
          # Only `union` nodes are handled further.
          def walk(node)
            return if node.nil?

            on_union(node) if node.type == :union

            node.child_nodes.each do |child|
              walk(child)
            end
          end

          # Search `union` nodes for `node_type` and `node_sequence` nodes that can be
          # collapsed into a node group.
          # * `node_type` nodes are nodes with no further configuration (ie. `send`)
          # * `node_sequence` nodes are nodes with further configuration (ie. `(send ...)`)
          #
          # Each group of types that can be collapsed will have a `NodeGroup` record added
          # to `node_groups`, which is then used by the cop.
          def on_union(node)
            all_node_types = each_child_node(node, :node_type, :node_sequence).to_a

            each_node_group(all_node_types) do |group_name, node_types|
              next unless sequences_match?(node_types)

              node_groups << node_group_data(
                group_name, node, node_types,
                all_node_types.index(node_types.first),
                (node.children - node_types).any?
              )
            end
          end

          private

          def each_child_node(node, *types)
            return to_enum(__method__, node, *types) unless block_given?

            node.children.each do |child|
              yield child if types.empty? || types.include?(child.type)
            end

            self
          end

          def each_node_group(types_to_check)
            # Find all node groups where all of the members are present in the union
            type_names = types_to_check.map(&:child)

            NODE_GROUPS.select { |_, group| group & type_names == group }.each_key do |name|
              nodes = get_relevant_nodes(types_to_check, name)

              yield name, nodes
            end
          end

          def get_relevant_nodes(node_types, group_name)
            node_types.each_with_object([]) do |node_type, arr|
              next unless NODE_GROUPS[group_name].include?(node_type.child)

              arr << node_type
            end
          end

          def node_group_data(name, union, node_types, start_index, other)
            NodeGroup.new(
              name: name,
              union: union,
              node_types: node_types,
              sequence?: node_types.first.type == :node_sequence,
              start_index: start_index,
              pipe: union.source_range.source['|'],
              other_elements?: other
            )
          end

          def sequences_match?(types)
            # Ensure all given types have the same type and the same sequence
            # ie. `(send ...)` and `(csend ...) is a match
            #     `(send)` and `(csend ...)` is not a match
            #     `send` and `(csend ...)` is not a match

            types.each_cons(2).all? do |left, right|
              left.type == right.type && left.children[1..] == right.children[1..]
            end
          end
        end
      end
      # rubocop:enable InternalAffairs/RedundantSourceRange
    end
  end
end
