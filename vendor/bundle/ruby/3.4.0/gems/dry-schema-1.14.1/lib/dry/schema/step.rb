# frozen_string_literal: true

require "dry/schema/constants"

module Dry
  module Schema
    # @api private
    class Step
      # @api private
      attr_reader :name

      # @api private
      attr_reader :type

      # @api private
      attr_reader :executor

      # @api private
      attr_reader :path

      # @api private
      def initialize(type:, name:, executor:, path: Path::EMPTY)
        @type = type
        @name = name
        @executor = executor
        @path = path
        validate_name(name)
      end

      # @api private
      def call(result)
        scoped_result = path.equal?(Path::EMPTY) ? result : result.at(path)

        output = executor.(scoped_result)
        scoped_result.replace(output) if output.is_a?(Hash)
        output
      end

      # @api private
      def scoped(parent_path)
        self.class.new(
          type: type,
          name: name,
          executor: executor,
          path: Path.new([*parent_path, *path])
        )
      end

      private

      # @api private
      def validate_name(name)
        return if STEPS_IN_ORDER.include?(name)

        raise ArgumentError, "Undefined step name #{name}. Available names: #{STEPS_IN_ORDER}"
      end
    end
  end
end
