# frozen_string_literal: true

module Dry
  module Schema
    module Macros
      # Macro used to specify a nested schema
      #
      # @api private
      class Schema < Value
        # @api private
        def call(*args, &block)
          super(*args, &nil) unless args.empty?

          if args.size.equal?(1) && (op = args.first).is_a?(::Dry::Logic::Operations::Abstract)
            process_operation(op)
          end

          if block
            schema = define(*args, &block)
            import_steps(schema)
            trace << schema.to_rule
          end

          self
        end

        private

        # @api private
        def process_operation(op)
          type(hash_type.schema(merge_operation_types(op)))
        end

        # @api private
        def hash_type
          schema_dsl.resolve_type(:hash)
        end

        # @api private
        def merge_operation_types(op)
          op.rules.reduce({}) do |acc, rule|
            types =
              case rule
              when Dry::Logic::Operations::Abstract
                merge_operation_types(rule)
              when Processor
                rule.types
              else
                EMPTY_HASH.dup
              end

            schema_dsl.merge_types(op.class, acc, types)
          end
        end

        # @api private
        # rubocop: disable Metrics/AbcSize
        def define(*args, &)
          definition = schema_dsl.new(path: schema_dsl.path, &)
          schema = definition.call
          type_schema =
            if array_type?(parent_type)
              build_array_type(parent_type, definition.strict_type_schema)
            elsif redefined_schema?(args)
              parent_type.schema(definition.types)
            else
              definition.strict_type_schema
            end
          final_type = optional? ? type_schema.optional : type_schema

          type(final_type)

          if schema.filter_rules?
            schema_dsl[name].filter { hash?.then(schema(schema.filter_schema)) }
          end

          schema
        end
        # rubocop: enable Metrics/AbcSize

        # @api private
        def parent_type
          schema_dsl.types[name]
        end

        # @api private
        def optional?
          parent_type.optional?
        end

        # @api private
        def schema?
          parent_type.respond_to?(:schema)
        end

        # @api private
        def redefined_schema?(args)
          schema? && args.first.is_a?(Processor)
        end
      end
    end
  end
end
