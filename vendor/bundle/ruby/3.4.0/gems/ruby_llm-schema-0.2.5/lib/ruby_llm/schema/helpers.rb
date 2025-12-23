# frozen_string_literal: true

module RubyLLM
  module Helpers
    def schema(name = nil, description: nil, &block)
      schema_class = Schema.create(&block)
      schema_class.new(name, description: description)
    end
  end
end
