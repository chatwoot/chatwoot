# frozen_string_literal: true

require "dry/schema/extensions/info/schema_compiler"

module Dry
  module Schema
    # Info extension
    #
    # @api public
    module Info
      module SchemaMethods
        # Return information about keys and types
        #
        # @return [Hash<Symbol=>Hash>]
        #
        # @api public
        def info
          compiler = SchemaCompiler.new
          compiler.call(to_ast)
          compiler.to_h
        end
      end
    end

    Processor.include(Info::SchemaMethods)
  end
end
