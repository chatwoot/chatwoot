# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `csend` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available
    # to all `csend` nodes within RuboCop.
    class CsendNode < SendNode
      def send_type?
        false
      end
    end
  end
end
