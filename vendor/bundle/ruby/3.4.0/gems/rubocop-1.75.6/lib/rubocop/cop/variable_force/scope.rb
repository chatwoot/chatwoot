# frozen_string_literal: true

module RuboCop
  module Cop
    class VariableForce
      # A Scope represents a context of local variable visibility.
      # This is a place where local variables belong to.
      # A scope instance holds a scope node and variable entries.
      class Scope
        OUTER_SCOPE_CHILD_INDICES = {
          defs:   0..0,
          module: 0..0,
          class:  0..1,
          sclass: 0..0,
          block:  0..0
        }.freeze

        attr_reader :node, :variables, :naked_top_level

        alias naked_top_level? naked_top_level

        def initialize(node)
          unless SCOPE_TYPES.include?(node.type)
            # Accept any node type for top level scope
            if node.parent
              raise ArgumentError, "Node type must be any of #{SCOPE_TYPES}, passed #{node.type}"
            end

            @naked_top_level = true
          end
          @node = node
          @variables = {}
        end

        def ==(other)
          @node.equal?(other.node)
        end

        def name
          @node.method_name
        end

        def body_node
          if naked_top_level?
            node
          else
            child_index = case node.type
                          when :module, :sclass then 1
                          when :def, :class, :block, :numblock, :itblock then 2
                          when :defs then 3
                          end

            node.children[child_index]
          end
        end

        def include?(target_node)
          !belong_to_outer_scope?(target_node) && !belong_to_inner_scope?(target_node)
        end

        def each_node(&block)
          return to_enum(__method__) unless block

          yield node if naked_top_level?
          scan_node(node, &block)
        end

        private

        def scan_node(node, &block)
          node.each_child_node do |child_node|
            next unless include?(child_node)

            yield child_node
            scan_node(child_node, &block)
          end
        end

        def belong_to_outer_scope?(target_node)
          return true if !naked_top_level? && target_node.equal?(node)
          return true if ancestor_node?(target_node)
          return false unless target_node.parent.equal?(node)

          indices = OUTER_SCOPE_CHILD_INDICES[target_node.parent.type]
          return false unless indices

          indices.include?(target_node.sibling_index)
        end

        def belong_to_inner_scope?(target_node)
          return false if !target_node.parent || target_node.parent.equal?(node)
          return false unless SCOPE_TYPES.include?(target_node.parent.type)

          indices = OUTER_SCOPE_CHILD_INDICES[target_node.parent.type]
          return true unless indices

          !indices.include?(target_node.sibling_index)
        end

        def ancestor_node?(target_node)
          node.each_ancestor.any? { |ancestor_node| ancestor_node.equal?(target_node) }
        end
      end
    end
  end
end
