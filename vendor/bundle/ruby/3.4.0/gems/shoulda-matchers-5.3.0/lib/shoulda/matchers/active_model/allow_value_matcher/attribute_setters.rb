module Shoulda
  module Matchers
    module ActiveModel
      class AllowValueMatcher
        # @private
        class AttributeSetters
          include Enumerable

          def initialize(allow_value_matcher, values)
            @tuples = values.map do |attribute_name, value|
              AttributeSetterAndValidator.new(
                allow_value_matcher,
                attribute_name,
                value,
              )
            end
          end

          def each(&block)
            tuples.each(&block)
          end

          def first_failing
            tuples.detect(&method(:does_not_match?))
          end

          protected

          attr_reader :tuples

          private

          def does_not_match?(tuple)
            !tuple.attribute_setter.set!
          end
        end
      end
    end
  end
end
