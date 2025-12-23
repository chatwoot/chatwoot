# frozen_string_literal: true

module Dry
  module Types
    # A registry with predicate objects from `Dry::Logic::Predicates`
    #
    # @api private
    class PredicateRegistry
      # @api private
      attr_reader :predicates

      # @api private
      attr_reader :has_predicate

      KERNEL_RESPOND_TO = ::Kernel.instance_method(:respond_to?)
      private_constant(:KERNEL_RESPOND_TO)

      # @api private
      def initialize(predicates = Logic::Predicates)
        @predicates = predicates
      end

      # @api private
      def key?(name)
        KERNEL_RESPOND_TO.bind_call(@predicates, name)
      end

      # @api private
      def [](name) = predicates[name]
    end
  end
end
