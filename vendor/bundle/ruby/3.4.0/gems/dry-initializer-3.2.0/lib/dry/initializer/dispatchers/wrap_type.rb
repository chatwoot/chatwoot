# frozen_string_literal: true

# Takes `:type` and `:wrap` to construct the final value coercer
#
module Dry
  module Initializer
    module Dispatchers
      module WrapType
        extend self

        def call(type: nil, wrap: 0, **options)
          {type: wrapped_type(type, wrap), **options}
        end

        private

        def wrapped_type(type, count)
          return type if count.zero?

          ->(value) { wrap_value(value, count, type) }
        end

        def wrap_value(value, count, type)
          if count.zero?
            type ? type.call(value) : value
          else
            return [wrap_value(value, count - 1, type)] unless value.is_a?(Array)

            value.map { |item| wrap_value(item, count - 1, type) }
          end
        end
      end
    end
  end
end
