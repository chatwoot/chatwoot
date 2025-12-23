# frozen_string_literal: true

module Dry
  module Core
    class InvalidClassAttributeValueError < ::StandardError
      def initialize(name, value)
        super(
          "Value #{value.inspect} is invalid for class attribute #{name.inspect}"
        )
      end
    end
  end
end
