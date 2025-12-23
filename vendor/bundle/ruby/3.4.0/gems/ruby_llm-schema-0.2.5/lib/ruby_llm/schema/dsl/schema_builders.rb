# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module SchemaBuilders
        def string_schema(description: nil, enum: nil, min_length: nil, max_length: nil, pattern: nil, format: nil)
          {
            type: "string",
            enum: enum,
            description: description,
            minLength: min_length,
            maxLength: max_length,
            pattern: pattern,
            format: format
          }.compact
        end

        def number_schema(description: nil, minimum: nil, maximum: nil, multiple_of: nil)
          {
            type: "number",
            description: description,
            minimum: minimum,
            maximum: maximum,
            multipleOf: multiple_of
          }.compact
        end

        def integer_schema(description: nil, minimum: nil, maximum: nil, multiple_of: nil)
          {
            type: "integer",
            description: description,
            minimum: minimum,
            maximum: maximum,
            multipleOf: multiple_of
          }.compact
        end

        def boolean_schema(description: nil)
          {type: "boolean", description: description}.compact
        end

        def null_schema(description: nil)
          {type: "null", description: description}.compact
        end

        def object_schema(description: nil, of: nil, reference: nil, &block)
          if reference
            warn "[DEPRECATION] The `reference` option will be deprecated. Please use `of` instead."
            of = reference
          end

          if of
            determine_object_reference(of, description)
          else
            sub_schema = Class.new(Schema)
            result = sub_schema.class_eval(&block)

            # If the block returned a reference and no properties were added, use the reference
            if result.is_a?(Hash) && result["$ref"] && sub_schema.properties.empty?
              result.merge(description ? {description: description} : {})
            # If the block returned a Schema class or instance, convert it to inline schema
            elsif schema_class?(result) && sub_schema.properties.empty?
              schema_class_to_inline_schema(result).merge(description ? {description: description} : {})
            # Block didn't return reference or schema, so we build an inline object schema
            else
              {
                type: "object",
                properties: sub_schema.properties,
                required: sub_schema.required_properties,
                additionalProperties: sub_schema.additional_properties,
                description: description
              }.compact
            end
          end
        end

        def array_schema(description: nil, of: nil, min_items: nil, max_items: nil, &block)
          items = determine_array_items(of, &block)

          {
            type: "array",
            description: description,
            items: items,
            minItems: min_items,
            maxItems: max_items
          }.compact
        end

        def any_of_schema(description: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            anyOf: schemas
          }.compact
        end

        def one_of_schema(description: nil, &block)
          schemas = collect_schemas_from_block(&block)

          {
            description: description,
            oneOf: schemas
          }.compact
        end

        private

        def determine_array_items(of, &)
          return collect_schemas_from_block(&).first if block_given?
          return send("#{of}_schema") if primitive_type?(of)
          return reference(of) if of.is_a?(Symbol)
          return schema_class_to_inline_schema(of) if schema_class?(of)

          raise InvalidArrayTypeError, "Invalid array type: #{of.inspect}. Must be a primitive type (:string, :number, etc.), a symbol reference, a Schema class, or a Schema instance."
        end

        def determine_object_reference(of, description = nil)
          result = case of
          when Symbol
            reference(of)
          when Class
            if schema_class?(of)
              schema_class_to_inline_schema(of)
            else
              raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Class must inherit from RubyLLM::Schema."
            end
          else
            if schema_class?(of)
              schema_class_to_inline_schema(of)
            else
              raise InvalidObjectTypeError, "Invalid object type: #{of.inspect}. Must be a symbol reference, a Schema class, or a Schema instance."
            end
          end

          description ? result.merge(description: description) : result
        end

        def collect_schemas_from_block(&block)
          schemas = []
          schema_builder = self

          context = Object.new

          # Dynamically create methods for all schema builders
          schema_builder.methods.grep(/_schema$/).each do |schema_method|
            type_name = schema_method.to_s.sub(/_schema$/, "")

            context.define_singleton_method(type_name) do |name = nil, **options, &blk|
              schemas << schema_builder.send(schema_method, **options, &blk)
            end
          end

          # Allow Schema classes to be accessed in the context
          context.define_singleton_method(:const_missing) do |name|
            const_get(name) if const_defined?(name)
          end

          context.instance_eval(&block)
          schemas
        end

        def schema_class_to_inline_schema(schema_class_or_instance)
          # Handle both Schema classes and Schema instances
          schema_class = if schema_class_or_instance.is_a?(Class)
            schema_class_or_instance
          else
            schema_class_or_instance.class
          end

          # Directly convert schema class to inline object schema
          {
            type: "object",
            properties: schema_class.properties,
            required: schema_class.required_properties,
            additionalProperties: schema_class.additional_properties
          }.tap do |schema|
            # For instances, prefer instance description over class description
            description = if schema_class_or_instance.is_a?(Class)
              schema_class.description
            else
              schema_class_or_instance.instance_variable_get(:@description) || schema_class.description
            end
            schema[:description] = description if description
          end
        end
      end
    end
  end
end
