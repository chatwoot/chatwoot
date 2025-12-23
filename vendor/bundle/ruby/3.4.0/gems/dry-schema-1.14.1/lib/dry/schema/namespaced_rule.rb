# frozen_string_literal: true

module Dry
  module Schema
    # A special rule type that is configured under a specified namespace
    #
    # This is used internally to create rules that can be properly handled
    # by the message compiler in situations where a schema reuses another schema
    # but it is configured to use a message namespace
    #
    # @api private
    class NamespacedRule
      # @api private
      attr_reader :rule

      # @api private
      attr_reader :namespace

      # @api private
      def initialize(namespace, rule)
        @namespace = namespace
        @rule = rule
      end

      # @api private
      def call(input)
        result = rule.call(input)
        Logic::Result.new(result.success?) { [:namespace, [namespace, result.to_ast]] }
      end

      # @api private
      def ast(input = Undefined)
        [:namespace, [namespace, rule.ast(input)]]
      end
      alias_method :to_ast, :ast
    end
  end
end
