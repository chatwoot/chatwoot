# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # Macro used to prepend `:filled?` predicate
      #
      # @api private
      class Filled < Value
        # @api private
        def call(*predicates, **opts, &block)
          ensure_valid_predicates(predicates)

          append_macro(Macros::Value) do |macro|
            if opts[:type_spec] && !filter_empty_string?
              macro.call(predicates[0], :filled?, *predicates.drop(1), **opts, &block)
            elsif opts[:type_rule]
              macro.call(:filled?).value(*predicates, **opts, &block)
            else
              macro.call(:filled?, *predicates, **opts, &block)
            end
          end
        end

        # @api private
        def ensure_valid_predicates(predicates)
          if predicates.include?(:empty?)
            raise ::Dry::Schema::InvalidSchemaError, "Using filled with empty? predicate is invalid"
          end

          if predicates.include?(:filled?)
            raise ::Dry::Schema::InvalidSchemaError, "Using filled with filled? is redundant"
          end
        end

        # @api private
        def filter_empty_string?
          !expected_primitives.include?(NilClass) && processor_config.filter_empty_string
        end

        # @api private
        def processor_config
          schema_dsl.processor_type.config
        end

        # @api private
        def expected_primitives
          primitive_inferrer[schema_type]
        end

        # @api private
        def schema_type
          schema_dsl.types[name]
        end
      end
    end
  end
end
