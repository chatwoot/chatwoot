# frozen_string_literal: true

require 'set'

module RuboCop
  module Cop
    # Help methods for determining node visibility.
    module VisibilityHelp
      extend NodePattern::Macros

      VISIBILITY_SCOPES = ::Set[:private, :protected, :public].freeze

      private

      def node_visibility(node)
        node_visibility_from_visibility_inline(node) ||
          node_visibility_from_visibility_block(node) ||
          :public
      end

      def node_visibility_from_visibility_inline(node)
        return unless node.def_type?

        node_visibility_from_visibility_inline_on_def(node) ||
          node_visibility_from_visibility_inline_on_method_name(node)
      end

      def node_visibility_from_visibility_inline_on_def(node)
        parent = node.parent
        parent.method_name if visibility_inline_on_def?(parent)
      end

      def node_visibility_from_visibility_inline_on_method_name(node)
        node.right_siblings.reverse.find do |sibling|
          visibility_inline_on_method_name?(sibling, method_name: node.method_name)
        end&.method_name
      end

      def node_visibility_from_visibility_block(node)
        find_visibility_start(node)&.method_name
      end

      def find_visibility_start(node)
        node.left_siblings.reverse.find { |sibling| visibility_block?(sibling) }
      end

      # Navigate to find the last protected method
      def find_visibility_end(node)
        possible_visibilities = VISIBILITY_SCOPES - ::Set[node_visibility(node)]
        right = node.right_siblings
        right.find do |child_node|
          possible_visibilities.include?(node_visibility(child_node))
        end || right.last
      end

      # @!method visibility_block?(node)
      def_node_matcher :visibility_block?, <<~PATTERN
        (send nil? VISIBILITY_SCOPES)
      PATTERN

      # @!method visibility_inline_on_def?(node)
      def_node_matcher :visibility_inline_on_def?, <<~PATTERN
        (send nil? VISIBILITY_SCOPES def)
      PATTERN

      # @!method visibility_inline_on_method_name?(node, method_name:)
      def_node_matcher :visibility_inline_on_method_name?, <<~PATTERN
        (send nil? VISIBILITY_SCOPES (sym %method_name))
      PATTERN
    end
  end
end
