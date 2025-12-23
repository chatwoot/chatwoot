require 'forwardable'

module Shoulda
  module Matchers
    module ActiveModel
      module NumericalityMatchers
        # @private
        class NumericTypeMatcher
          extend Forwardable

          def_delegators(
            :disallow_value_matcher,
            :expects_custom_validation_message?,
            :expects_strict?,
            :failure_message,
            :failure_message_when_negated,
            :ignore_interference_by_writer,
            :ignoring_interference_by_writer,
            :matches?,
            :does_not_match?,
            :on,
            :strict,
            :with_message,
          )

          def initialize(numeric_type_matcher, attribute)
            @numeric_type_matcher = numeric_type_matcher
            @attribute = attribute
          end

          def allowed_type_name
            'number'
          end

          def allowed_type_adjective
            ''
          end

          def diff_to_compare
            raise NotImplementedError
          end

          protected

          attr_reader :attribute

          def wrap_disallow_value_matcher(_matcher)
            raise NotImplementedError
          end

          def disallowed_value
            raise NotImplementedError
          end

          private

          def disallow_value_matcher
            @_disallow_value_matcher ||= DisallowValueMatcher.new(disallowed_value).tap do |matcher|
              matcher.for(attribute)
              wrap_disallow_value_matcher(matcher)
            end
          end
        end
      end
    end
  end
end
