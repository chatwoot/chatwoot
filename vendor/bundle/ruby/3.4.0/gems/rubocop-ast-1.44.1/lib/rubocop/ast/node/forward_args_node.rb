# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `forward-args` nodes. This will be used in place
    # of a plain node when the builder constructs the AST, making its methods
    # available to all `forward-args` nodes within RuboCop.
    #
    # Not used with modern emitters:
    #
    #   $ ruby-parse -e "def foo(...); end"
    #   (def :foo
    #     (args
    #       (forward-arg)) nil)
    #   $ ruby-parse --legacy -e "->(foo) { bar }"
    #   (def :foo
    #     (forward-args) nil)
    #
    # Note the extra 's' with legacy form.
    #
    # The main RuboCop runs in legacy mode; this node is only used
    # if user `AST::Builder.modernize` or `AST::Builder.emit_lambda=true`
    class ForwardArgsNode < Node
      include CollectionNode

      # Node wraps itself in an array to be compatible with other
      # enumerable argument types.
      def to_a
        [self]
      end
    end
  end
end
