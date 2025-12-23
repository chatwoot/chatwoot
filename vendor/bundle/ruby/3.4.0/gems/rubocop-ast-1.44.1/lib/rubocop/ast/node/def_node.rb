# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `def` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `def` nodes within RuboCop.
    class DefNode < Node
      include ParameterizedNode
      include MethodIdentifierPredicates

      # Checks whether this node body is a void context.
      #
      # @return [Boolean] whether the `def` node body is a void context
      def void_context?
        (def_type? && method?(:initialize)) || assignment_method?
      end

      # Checks whether this method definition node forwards its arguments
      # as per the feature added in Ruby 2.7.
      #
      # @note This is written in a way that may support lead arguments
      #       which are rumored to be added in a later version of Ruby.
      #
      # @return [Boolean] whether the `def` node uses argument forwarding
      def argument_forwarding?
        arguments.any?(&:forward_args_type?) || arguments.any?(&:forward_arg_type?)
      end

      # The name of the defined method as a symbol.
      #
      # @return [Symbol] the name of the defined method
      def method_name
        children[-3]
      end

      # An array containing the arguments of the method definition.
      #
      # @return [Array<Node>] the arguments of the method definition
      def arguments
        children[-2]
      end

      # The body of the method definition.
      #
      # @note this can be either a `begin` node, if the method body contains
      #       multiple expressions, or any other node, if it contains a single
      #       expression.
      #
      # @return [Node] the body of the method definition
      def body
        children[-1]
      end

      # The receiver of the method definition, if any.
      #
      # @return [Node, nil] the receiver of the method definition, or `nil`.
      def receiver
        children[-4]
      end

      # @return [Boolean] if the definition is without an `end` or not.
      def endless?
        !loc.end
      end
    end
  end
end
