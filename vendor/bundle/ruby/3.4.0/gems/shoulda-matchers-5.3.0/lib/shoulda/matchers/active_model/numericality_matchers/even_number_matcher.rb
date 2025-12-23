module Shoulda
  module Matchers
    module ActiveModel
      module NumericalityMatchers
        # @private
        class EvenNumberMatcher < NumericTypeMatcher
          NON_EVEN_NUMBER_VALUE = 1

          def simple_description
            description = ''

            if expects_strict?
              description << 'strictly '
            end

            description +
              "disallow :#{attribute} from being an odd number"
          end

          def allowed_type_adjective
            'even'
          end

          def diff_to_compare
            2
          end

          protected

          def wrap_disallow_value_matcher(matcher)
            matcher.with_message(:even)
          end

          def disallowed_value
            if @numeric_type_matcher.given_numeric_column?
              NON_EVEN_NUMBER_VALUE
            else
              NON_EVEN_NUMBER_VALUE.to_s
            end
          end
        end
      end
    end
  end
end
