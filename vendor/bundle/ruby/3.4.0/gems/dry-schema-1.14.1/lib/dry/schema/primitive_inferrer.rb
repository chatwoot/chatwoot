# frozen_string_literal: true

module Dry
  module Schema
    # @api private
    class PrimitiveInferrer < ::Dry::Types::PrimitiveInferrer
      Compiler = ::Class.new(superclass::Compiler)

      def initialize
        super

        @compiler = Compiler.new
      end
    end
  end
end
