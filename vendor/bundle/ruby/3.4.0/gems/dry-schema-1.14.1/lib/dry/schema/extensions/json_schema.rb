# frozen_string_literal: true

require "dry/schema/extensions/json_schema/schema_compiler"

module Dry
  module Schema
    # JSONSchema extension
    #
    # @api public
    module JSONSchema
      module SchemaMethods
        # Convert the schema into a JSON schema hash
        #
        # @param [Symbol] loose Compile the schema in "loose" mode
        #
        # @return [Hash<Symbol=>Hash>]
        #
        # @api public
        def json_schema(loose: false)
          compiler = SchemaCompiler.new(root: true, loose: loose)
          compiler.call(to_ast)
          compiler.to_hash
        end
      end
    end

    Processor.include(JSONSchema::SchemaMethods)
  end
end
