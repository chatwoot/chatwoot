# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for working with string interpolations.
    #
    # @abstract Subclasses are expected to implement {#on_interpolation}.
    module Interpolation
      def on_dstr(node)
        on_node_with_interpolations(node)
      end

      alias on_xstr on_dstr
      alias on_dsym on_dstr
      alias on_regexp on_dstr

      def on_node_with_interpolations(node)
        node.each_child_node(:begin) { |begin_node| on_interpolation(begin_node) }
      end

      # @!method on_interpolation(begin_node)
      #   Inspect the `:begin` node of an interpolation
    end
  end
end
