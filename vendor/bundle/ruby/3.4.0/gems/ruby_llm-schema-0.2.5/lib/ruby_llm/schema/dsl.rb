# frozen_string_literal: true

require_relative "dsl/schema_builders"
require_relative "dsl/primitive_types"
require_relative "dsl/complex_types"
require_relative "dsl/utilities"

module RubyLLM
  class Schema
    module DSL
      include SchemaBuilders
      include PrimitiveTypes
      include ComplexTypes
      include Utilities
    end
  end
end
