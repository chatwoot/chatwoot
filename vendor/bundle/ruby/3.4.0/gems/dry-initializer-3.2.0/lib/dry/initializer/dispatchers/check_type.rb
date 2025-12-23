# frozen_string_literal: true

# Checks whether an unwrapped type is valid
#
module Dry
  module Initializer
    module Dispatchers
      module CheckType
        extend self

        def call(source:, type: nil, wrap: 0, **options)
          check_if_callable! source, type
          check_arity! source, type, wrap

          {source:, type:, wrap:, **options}
        end

        private

        def check_if_callable!(source, type)
          return if type.nil?
          return if type.respond_to?(:call)

          raise ArgumentError,
                "The type of the argument '#{source}' should be callable"
        end

        def check_arity!(_source, type, wrap)
          return if type.nil?
          return if wrap.zero?
          return if type.method(:call).arity.abs == 1

          raise ArgumentError, <<~MESSAGE
            The dry_intitializer supports wrapped types with one argument only.
            You cannot use array types with element coercers having several arguments.

            For example, this definitions are correct:
              option :foo, [proc(&:to_s)]
              option :bar, type: [[]]
              option :baz, ->(a, b) { [a, b] }

            While this is not:
              option :foo, [->(a, b) { [a, b] }]
          MESSAGE
        end
      end
    end
  end
end
