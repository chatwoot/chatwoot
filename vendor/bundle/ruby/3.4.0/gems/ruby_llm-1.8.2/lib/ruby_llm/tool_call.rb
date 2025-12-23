# frozen_string_literal: true

module RubyLLM
  # Represents a function call from an AI model to a Tool.
  class ToolCall
    attr_reader :id, :name, :arguments

    def initialize(id:, name:, arguments: {})
      @id = id
      @name = name
      @arguments = arguments
    end

    def to_h
      {
        id: @id,
        name: @name,
        arguments: @arguments
      }
    end
  end
end
