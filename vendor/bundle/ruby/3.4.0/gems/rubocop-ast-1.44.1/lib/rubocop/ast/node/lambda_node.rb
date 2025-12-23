# frozen_string_literal: true

module RuboCop
  module AST
    # Used for modern support only:
    # Not as thoroughly tested as legacy equivalent
    #
    #   $ ruby-parse -e "->(foo) { bar }"
    #   (block
    #     (lambda)
    #     (args
    #       (arg :foo))
    #     (send nil :bar))
    #   $ ruby-parse --legacy -e "->(foo) { bar }"
    #   (block
    #     (send nil :lambda)
    #     (args
    #       (arg :foo))
    #     (send nil :bar))
    #
    # The main RuboCop runs in legacy mode; this node is only used
    # if user `AST::Builder.modernize` or `AST::Builder.emit_lambda=true`
    class LambdaNode < Node
      include ParameterizedNode::RestArguments
      include MethodDispatchNode

      # For similarity with legacy mode
      def lambda?
        true
      end

      # For similarity with legacy mode
      def lambda_literal?
        true
      end

      # For similarity with legacy mode
      def attribute_accessor?
        false
      end

      # For similarity with legacy mode
      def assignment_method?
        false
      end

      # For similarity with legacy mode
      def receiver
        nil
      end

      # For similarity with legacy mode
      def method_name
        :lambda
      end

      private

      # For similarity with legacy mode
      def first_argument_index
        2
      end
    end
  end
end
