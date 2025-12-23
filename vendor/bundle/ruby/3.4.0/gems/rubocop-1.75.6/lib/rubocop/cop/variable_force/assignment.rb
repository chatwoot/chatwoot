# frozen_string_literal: true

module RuboCop
  module Cop
    class VariableForce
      # This class represents each assignment of a variable.
      class Assignment
        include Branchable

        MULTIPLE_LEFT_HAND_SIDE_TYPE = :mlhs

        attr_reader :node, :variable, :referenced, :references, :reassigned

        alias referenced? referenced
        alias reassigned? reassigned

        def initialize(node, variable)
          unless VARIABLE_ASSIGNMENT_TYPES.include?(node.type)
            raise ArgumentError,
                  "Node type must be any of #{VARIABLE_ASSIGNMENT_TYPES}, " \
                  "passed #{node.type}"
          end

          @node = node
          @variable = variable
          @referenced = false
          @references = []
          @reassigned = false
        end

        def name
          @node.children.first
        end

        def scope
          @variable.scope
        end

        def reference!(node)
          @references << node
          @referenced = true
        end

        def reassigned!
          return if referenced?

          @reassigned = true
        end

        def used?
          (!reassigned? && @variable.captured_by_block?) || @referenced
        end

        def regexp_named_capture?
          @node.type == REGEXP_NAMED_CAPTURE_TYPE
        end

        def exception_assignment?
          node.parent&.resbody_type? && node.parent.exception_variable == node
        end

        def operator_assignment?
          return false unless meta_assignment_node

          OPERATOR_ASSIGNMENT_TYPES.include?(meta_assignment_node.type)
        end

        def multiple_assignment?
          return false unless meta_assignment_node

          meta_assignment_node.type == MULTIPLE_ASSIGNMENT_TYPE
        end

        def rest_assignment?
          return false unless meta_assignment_node

          meta_assignment_node.type == REST_ASSIGNMENT_TYPE
        end

        def for_assignment?
          return false unless meta_assignment_node

          meta_assignment_node.for_type?
        end

        def operator
          assignment_node = meta_assignment_node || @node
          assignment_node.loc.operator.source
        end

        def meta_assignment_node
          unless instance_variable_defined?(:@meta_assignment_node)
            @meta_assignment_node = operator_assignment_node ||
                                    multiple_assignment_node ||
                                    rest_assignment_node ||
                                    for_assignment_node
          end

          @meta_assignment_node
        end

        private

        def operator_assignment_node
          return nil unless node.parent
          return nil unless OPERATOR_ASSIGNMENT_TYPES.include?(node.parent.type)
          return nil unless node.sibling_index.zero?

          node.parent
        end

        def multiple_assignment_node
          return nil unless node.parent&.mlhs_type?
          return nil unless (grandparent_node = node.parent&.parent)
          if (node = find_multiple_assignment_node(grandparent_node))
            return node
          end
          return nil unless grandparent_node.type == MULTIPLE_ASSIGNMENT_TYPE

          grandparent_node
        end

        def rest_assignment_node
          return nil unless node.parent
          return nil unless node.parent.type == REST_ASSIGNMENT_TYPE

          node.parent
        end

        def for_assignment_node
          return unless (parent_node = node.parent)
          return parent_node if parent_node.for_type?

          grandparent_node = parent_node.parent
          return grandparent_node if parent_node.mlhs_type? && grandparent_node&.for_type?

          nil
        end

        def find_multiple_assignment_node(grandparent_node)
          return unless grandparent_node.type == MULTIPLE_LEFT_HAND_SIDE_TYPE
          return if grandparent_node.children.any?(&:splat_type?)

          parent = grandparent_node.parent
          return parent if parent.type == MULTIPLE_ASSIGNMENT_TYPE

          find_multiple_assignment_node(parent)
        end
      end
    end
  end
end
