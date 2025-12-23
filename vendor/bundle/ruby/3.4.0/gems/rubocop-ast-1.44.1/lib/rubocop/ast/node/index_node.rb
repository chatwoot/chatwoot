# frozen_string_literal: true

module RuboCop
  module AST
    # Used for modern support only!
    # Not as thoroughly tested as legacy equivalent
    #
    #   $ ruby-parse -e "foo[:bar]"
    #   (index
    #     (send nil :foo)
    #     (sym :bar))
    #   $ ruby-parse --legacy -e "foo[:bar]"
    #   (send
    #     (send nil :foo) :[]
    #     (sym :bar))
    #
    # The main RuboCop runs in legacy mode; this node is only used
    # if user `AST::Builder.modernize` or `AST::Builder.emit_index=true`
    class IndexNode < Node
      include ParameterizedNode::RestArguments
      include MethodDispatchNode

      # For similarity with legacy mode
      def attribute_accessor?
        false
      end

      # For similarity with legacy mode
      def assignment_method?
        false
      end

      # For similarity with legacy mode
      def method_name
        :[]
      end

      private

      # An array containing the arguments of the dispatched method.
      #
      # @return [Array<Node>] the arguments of the dispatched method
      def first_argument_index
        1
      end
    end
  end
end
