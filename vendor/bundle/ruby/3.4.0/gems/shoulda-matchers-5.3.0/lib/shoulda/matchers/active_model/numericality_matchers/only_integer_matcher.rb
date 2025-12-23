module Shoulda
  module Matchers
    module ActiveModel
      module NumericalityMatchers
        # @private
        class OnlyIntegerMatcher < NumericTypeMatcher
          NON_INTEGER_VALUE = 0.1

          def simple_description
            description = ''

            if expects_strict?
              description << ' strictly'
            end

            description + "disallow :#{attribute} from being a decimal number"
          end

          def allowed_type_name
            'integer'
          end

          def diff_to_compare
            1
          end

          protected

          def wrap_disallow_value_matcher(matcher)
            matcher.with_message(:not_an_integer)
          end

          def disallowed_value
            if @numeric_type_matcher.given_numeric_column?
              NON_INTEGER_VALUE
            else
              NON_INTEGER_VALUE.to_s
            end
          end
        end
      end
    end
  end
end
