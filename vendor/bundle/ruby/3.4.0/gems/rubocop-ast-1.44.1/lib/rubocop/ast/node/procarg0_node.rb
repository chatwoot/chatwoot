# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `procarg0` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all `arg` nodes within RuboCop.
    class Procarg0Node < ArgNode
      # Returns the name of an argument.
      #
      # @return [Symbol, nil] the name of the argument
      def name
        node_parts[0].name
      end
    end
  end
end
