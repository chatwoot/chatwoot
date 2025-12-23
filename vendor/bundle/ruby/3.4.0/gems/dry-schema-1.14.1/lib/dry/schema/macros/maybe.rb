# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # Macro used to specify predicates for a value that can be `nil`
      #
      # @api private
      class Maybe < DSL
        # @api private
        def call(*args, **opts, &block)
          if args.include?(:empty?)
            raise ::Dry::Schema::InvalidSchemaError, "Using maybe with empty? predicate is invalid"
          end

          if args.include?(:nil?)
            raise ::Dry::Schema::InvalidSchemaError, "Using maybe with nil? predicate is redundant"
          end

          append_macro(Macros::Value) do |macro|
            macro.call(*args, **opts, &block)
          end

          self
        end

        # @api private
        def to_ast
          [:implication,
           [
             [:not, [:predicate, [:nil?, [[:input, Undefined]]]]],
             trace.to_rule.to_ast
           ]]
        end
      end
    end
  end
end
