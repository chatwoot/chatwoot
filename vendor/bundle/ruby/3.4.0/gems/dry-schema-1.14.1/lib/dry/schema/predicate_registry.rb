# frozen_string_literal: true

module Dry
  module Schema
    # A registry with predicate objects from `Dry::Logic::Predicates`
    #
    # @api private
    class PredicateRegistry < ::Dry::Types::PredicateRegistry
      # @api private
      def arg_list(name, *values)
        predicate = self[name]
        # Cater for optional second argument like in case of `eql?` or `respond_to?`
        arity = predicate.arity.abs

        predicate
          .parameters
          .map(&:last)
          .zip(values + ::Array.new(arity - values.size, Undefined))
      end
    end
  end
end
