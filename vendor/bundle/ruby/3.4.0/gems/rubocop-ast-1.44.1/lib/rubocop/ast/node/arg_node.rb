# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `arg`, `optarg`, `restarg`, `kwarg`, `kwoptarg`,
    # `kwrestarg`, `blockarg`, `shadowarg` and `forward_arg` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all `arg` nodes within RuboCop.
    class ArgNode < Node
      # Returns the name of an argument.
      #
      # @return [Symbol, nil] the name of the argument
      def name
        node_parts[0]
      end

      # Returns the default value of the argument, if any.
      #
      # @return [Node, nil] the default value of the argument
      def default_value
        return unless default?

        node_parts[1]
      end

      # Checks whether the argument has a default value
      #
      # @return [Boolean] whether the argument has a default value
      def default?
        optarg_type? || kwoptarg_type?
      end
    end
  end
end
