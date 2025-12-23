# frozen_string_literal: true

module RubyLLM
  class Schema
    module DSL
      module Utilities
        # Schema definition and reference methods
        def define(name, &)
          sub_schema = Class.new(Schema)
          sub_schema.class_eval(&)

          definitions[name] = {
            type: "object",
            properties: sub_schema.properties,
            required: sub_schema.required_properties,
            additionalProperties: sub_schema.additional_properties
          }
        end

        def reference(schema_name)
          if schema_name == :root
            {"$ref" => "#"}
          else
            {"$ref" => "#/$defs/#{schema_name}"}
          end
        end

        private

        def add_property(name, definition, required:)
          properties[name.to_sym] = definition
          required_properties << name.to_sym if required
        end

        def primitive_type?(type)
          type.is_a?(Symbol) && PRIMITIVE_TYPES.include?(type)
        end

        def schema_class?(type)
          (type.is_a?(Class) && type < Schema) || type.is_a?(Schema)
        end
      end
    end
  end
end
