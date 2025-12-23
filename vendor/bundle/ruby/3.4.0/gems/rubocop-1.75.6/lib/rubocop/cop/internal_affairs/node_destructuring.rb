# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that node destructuring is using the node extensions.
      #
      # @example Using splat expansion
      #
      #   # bad
      #   _receiver, method_name, _arguments = send_node.children
      #
      #   # bad
      #   _receiver, method_name, _arguments = *send_node
      #
      #   # good
      #   method_name = send_node.method_name
      class NodeDestructuring < Base
        MSG = 'Use the methods provided with the node extensions instead ' \
              'of manually destructuring nodes.'

        # @!method node_variable?(node)
        def_node_matcher :node_variable?, <<~PATTERN
          {(lvar [#node_suffix? _]) (send nil? [#node_suffix? _])}
        PATTERN

        # @!method node_destructuring?(node)
        def_node_matcher :node_destructuring?, <<~PATTERN
          {(masgn (mlhs ...) {(send #node_variable? :children) (array (splat #node_variable?))})}
        PATTERN

        def on_masgn(node)
          node_destructuring?(node) { add_offense(node) }
        end

        private

        def node_suffix?(method_name)
          method_name.to_s.end_with?('node')
        end
      end
    end
  end
end
