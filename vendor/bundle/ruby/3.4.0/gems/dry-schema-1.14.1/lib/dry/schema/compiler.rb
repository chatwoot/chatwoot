# frozen_string_literal: true

module Dry
  module Schema
    # Extended rule compiler used internally by the DSL
    #
    # @api private
    class Compiler < Logic::RuleCompiler
      # Builds a default compiler instance with custom predicate registry
      #
      # @return [Compiler]
      #
      # @api private
      def self.new(predicates = PredicateRegistry.new)
        super
      end

      # @api private
      def visit_and(node)
        super.with(hints: false)
      end

      # Build a special rule that will produce namespaced failures
      #
      # This is needed for schemas that are namespaced and they are
      # used as nested schemas
      #
      # @param [Array] node
      # @param [Hash] _opts Unused
      #
      # @return [NamespacedRule]
      #
      # @api private
      def visit_namespace(node, _opts = EMPTY_HASH)
        namespace, rest = node
        NamespacedRule.new(namespace, visit(rest))
      end

      # Return true if a given predicate is supported by this compiler
      #
      # @param [Symbol] predicate
      #
      # @return [Boolean]
      #
      # @api private
      def support?(predicate)
        predicates.key?(predicate)
      end
    end
  end
end
