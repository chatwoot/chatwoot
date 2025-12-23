require 'forwardable'

module Shoulda
  module Matchers
    module ActiveModel
      class AllowValueMatcher
        # @private
        class AttributeSetterAndValidator
          extend Forwardable

          def_delegators(
            :allow_value_matcher,
            :after_setting_value_callback,
            :attribute_to_check_message_against,
            :context,
            :expected_message,
            :expects_strict?,
            :ignore_interference_by_writer,
            :instance,
          )

          def initialize(allow_value_matcher, attribute_name, value)
            @allow_value_matcher = allow_value_matcher
            @attribute_name = attribute_name
            @value = value
            @_attribute_setter = nil
            @_validator = nil
          end

          def attribute_setter
            @_attribute_setter ||= AttributeSetter.new(
              matcher_name: :allow_value,
              object: instance,
              attribute_name: attribute_name,
              value: value,
              ignore_interference_by_writer: ignore_interference_by_writer,
              after_set_callback: after_setting_value_callback,
            )
          end

          def attribute_setter_description
            attribute_setter.description
          end

          def validator
            @_validator ||= Validator.new(
              instance,
              attribute_to_check_message_against,
              context: context,
              expects_strict: expects_strict?,
              expected_message: expected_message,
            )
          end

          protected

          attr_reader :allow_value_matcher, :attribute_name, :value
        end
      end
    end
  end
end
