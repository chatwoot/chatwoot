# frozen_string_literal: true

module RubyLLM
  class Schema
    # Base error class for all schema-related errors
    class Error < StandardError; end

    # Raised when an invalid schema type is specified
    class InvalidSchemaTypeError < Error
      def initialize(type)
        super("Unknown schema type: #{type}")
      end
    end

    # Raised when an invalid array type is specified
    class InvalidArrayTypeError < Error
      def initialize(message)
        super
      end
    end

    # Raised when an invalid object type is specified
    class InvalidObjectTypeError < Error
      def initialize(message)
        super
      end
    end

    # Raised when schema definition is invalid
    class InvalidSchemaError < Error; end

    # Raised when schema validation fails
    class ValidationError < Error; end

    # Raised when maximum limits are exceeded
    class LimitExceededError < Error; end
  end
end
