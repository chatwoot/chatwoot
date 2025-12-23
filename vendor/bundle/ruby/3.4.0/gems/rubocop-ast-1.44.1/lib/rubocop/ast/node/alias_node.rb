# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `alias` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `alias` nodes within RuboCop.
    class AliasNode < Node
      # Returns the old identifier as specified by the `alias`.
      #
      # @return [SymbolNode] the old identifier
      def old_identifier
        node_parts[1]
      end

      # Returns the new identifier as specified by the `alias`.
      #
      # @return [SymbolNode] the new identifier
      def new_identifier
        node_parts[0]
      end
    end
  end
end
