# frozen_string_literal: true

module RuboCop
  module AST
    # Requires implementing `arguments`.
    #
    # Common functionality for nodes that are parameterized:
    # `send`, `super`, `zsuper`, `def`, `defs`
    # and (modern only): `index`, `indexasgn`, `lambda`
    module ParameterizedNode
      # Checks whether this node's arguments are wrapped in parentheses.
      #
      # @return [Boolean] whether this node's arguments are
      #                   wrapped in parentheses
      def parenthesized?
        loc_is?(:end, ')')
      end

      # A shorthand for getting the first argument of the node.
      # Equivalent to `arguments.first`.
      #
      # @return [Node, nil] the first argument of the node,
      #                     or `nil` if there are no arguments
      def first_argument
        arguments[0]
      end

      # A shorthand for getting the last argument of the node.
      # Equivalent to `arguments.last`.
      #
      # @return [Node, nil] the last argument of the node,
      #                     or `nil` if there are no arguments
      def last_argument
        arguments[-1]
      end

      # Checks whether this node has any arguments.
      #
      # @return [Boolean] whether this node has any arguments
      def arguments?
        !arguments.empty?
      end

      # Checks whether any argument of the node is a splat
      # argument, i.e. `*splat`.
      #
      # @return [Boolean] whether the node is a splat argument
      def splat_argument?
        arguments? &&
          (arguments.any?(&:splat_type?) || arguments.any?(&:restarg_type?))
      end
      alias rest_argument? splat_argument?

      # Whether the last argument of the node is a block pass,
      # i.e. `&block`.
      #
      # @return [Boolean] whether the last argument of the node is a block pass
      def block_argument?
        arguments? &&
          last_argument.type?(:block_pass, :blockarg)
      end

      # A specialized `ParameterizedNode` for node that have a single child
      # containing either `nil`, an argument, or a `begin` node with all the
      # arguments
      module WrappedArguments
        include ParameterizedNode
        # @return [Array] The arguments of the node.
        def arguments
          first = children.first
          if first&.begin_type?
            first.children
          else
            children
          end
        end
      end

      # A specialized `ParameterizedNode`.
      # Requires implementing `first_argument_index`
      # Implements `arguments` as `children[first_argument_index..-1]`
      # and optimizes other calls
      module RestArguments
        include ParameterizedNode

        EMPTY_ARGUMENTS = [].freeze

        # @return [Array<Node>] arguments, if any
        def arguments
          if arguments?
            children.drop(first_argument_index).freeze
          else
            # Skip unneeded Array allocation.
            EMPTY_ARGUMENTS
          end
        end

        # A shorthand for getting the first argument of the node.
        # Equivalent to `arguments.first`.
        #
        # @return [Node, nil] the first argument of the node,
        #                     or `nil` if there are no arguments
        def first_argument
          children[first_argument_index]
        end

        # A shorthand for getting the last argument of the node.
        # Equivalent to `arguments.last`.
        #
        # @return [Node, nil] the last argument of the node,
        #                     or `nil` if there are no arguments
        def last_argument
          children[-1] if arguments?
        end

        # Checks whether this node has any arguments.
        #
        # @return [Boolean] whether this node has any arguments
        def arguments?
          children.size > first_argument_index
        end
      end
    end
  end
end
