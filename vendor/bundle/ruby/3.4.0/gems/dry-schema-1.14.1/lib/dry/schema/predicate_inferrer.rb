# frozen_string_literal: true

module Dry
  module Schema
    # @api private
    class PredicateInferrer < ::Dry::Types::PredicateInferrer
      Compiler = ::Class.new(superclass::Compiler)

      def initialize(registry = PredicateRegistry.new)
        super

        @compiler = Compiler.new(registry)
      end
    end
  end
end
