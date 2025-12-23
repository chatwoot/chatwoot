# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `op_asgn` nodes.
    # This will be used in place of a plain node when the builder constructs
    # the AST, making its methods available to all assignment nodes within RuboCop.
    class OrAsgnNode < OpAsgnNode
      # The operator being used for assignment as a symbol.
      #
      # @return [Symbol] the assignment operator
      def operator
        :'||'
      end
    end
  end
end
