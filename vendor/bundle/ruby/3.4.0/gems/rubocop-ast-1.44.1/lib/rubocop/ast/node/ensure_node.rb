# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `ensure` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `ensure` nodes within RuboCop.
    class EnsureNode < Node
      DEPRECATION_WARNING_LOCATION_CACHE = [] # rubocop:disable Style/MutableConstant
      private_constant :DEPRECATION_WARNING_LOCATION_CACHE

      # Returns the body of the `ensure` clause.
      #
      # @return [Node, nil] The body of the `ensure`.
      # @deprecated Use `EnsureNode#branch`
      def body
        first_caller = caller(1..1).first

        unless DEPRECATION_WARNING_LOCATION_CACHE.include?(first_caller)
          warn '`EnsureNode#body` is deprecated and will be changed in the next major version of ' \
               'rubocop-ast. Use `EnsureNode#branch` instead to get the body of the `ensure` branch.'
          warn "Called from:\n#{caller.join("\n")}\n\n"

          DEPRECATION_WARNING_LOCATION_CACHE << first_caller
        end

        branch
      end

      # Returns an the ensure branch in the exception handling statement.
      #
      # @return [Node, nil] the body of the ensure branch.
      def branch
        node_parts[1]
      end

      # Returns the `rescue` node of the `ensure`, if present.
      #
      # @return [Node, nil] The `rescue` node.
      def rescue_node
        node_parts[0] if node_parts[0].rescue_type?
      end

      # Checks whether this node body is a void context.
      # Always `true` for `ensure`.
      #
      # @return [true] whether the `ensure` node body is a void context
      def void_context?
        true
      end
    end
  end
end
