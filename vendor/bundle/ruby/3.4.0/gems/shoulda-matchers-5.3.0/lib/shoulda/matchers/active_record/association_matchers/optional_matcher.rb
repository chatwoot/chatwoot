module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class OptionalMatcher
          attr_reader :missing_option

          def initialize(attribute_name, optional)
            @attribute_name = attribute_name
            @optional = optional
            @submatcher = ActiveModel::AllowValueMatcher.new(nil).
              for(attribute_name)
            @missing_option = ''
          end

          def description
            "optional: #{optional}"
          end

          def matches?(subject)
            if submatcher_passes?(subject)
              true
            else
              @missing_option = 'and for the record '

              missing_option <<
                if optional
                  'not to '
                else
                  'to '
                end

              missing_option << (
                'fail validation if '\
                ":#{attribute_name} is unset; i.e., either the association "\
                'should have been defined with `optional: '\
                "#{optional.inspect}`, or there "
              )

              missing_option <<
                if optional
                  'should not '
                else
                  'should '
                end

              missing_option << "be a presence validation on :#{attribute_name}"

              false
            end
          end

          private

          attr_reader :attribute_name, :optional, :submatcher

          def submatcher_passes?(subject)
            if optional
              submatcher.matches?(subject)
            else
              submatcher.does_not_match?(subject)
            end
          end
        end
      end
    end
  end
end
