# frozen_string_literal: true

require_relative "schema/version"
require_relative "schema/errors"
require_relative "schema/helpers"
require_relative "schema/validator"
require_relative "schema/dsl"
require_relative "schema/json_output"
require "json"

module RubyLLM
  class Schema
    extend DSL
    include JsonOutput

    PRIMITIVE_TYPES = %i[string number integer boolean null].freeze

    class << self
      def create(&block)
        schema_class = Class.new(Schema)
        schema_class.class_eval(&block)
        schema_class
      end

      def properties
        @properties ||= {}
      end

      def required_properties
        @required_properties ||= []
      end

      def definitions
        @definitions ||= {}
      end

      def name(name = nil)
        @schema_name = name if name
        return @schema_name if defined?(@schema_name)

        super()
      end

      def description(description = nil)
        @description = description if description
        @description
      end

      def additional_properties(value = nil)
        return @additional_properties ||= false if value.nil?
        @additional_properties = value
      end

      def strict(value = nil)
        if value.nil?
          return @strict.nil? ? (@strict = true) : @strict
        end
        @strict = value
      end

      def validate!
        validator = Validator.new(self)
        validator.validate!
      end

      def valid?
        validator = Validator.new(self)
        validator.valid?
      end
    end

    def initialize(name = nil, description: nil)
      @name = name || self.class.name || "Schema"
      @description = description
    end

    def validate!
      self.class.validate!
    end

    def valid?
      self.class.valid?
    end

    def method_missing(method_name, ...)
      if respond_to_missing?(method_name)
        self.class.send(method_name, ...)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      %i[string number integer boolean array object any_of one_of null].include?(method_name) || super
    end
  end
end
