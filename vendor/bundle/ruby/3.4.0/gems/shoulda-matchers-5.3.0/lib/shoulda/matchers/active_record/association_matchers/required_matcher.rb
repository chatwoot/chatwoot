module Shoulda
  module Matchers
    module ActiveRecord
      module AssociationMatchers
        # @private
        class RequiredMatcher
          attr_reader :missing_option

          def initialize(attribute_name, required)
            @attribute_name = attribute_name
            @required = required
            @submatcher = ActiveModel::DisallowValueMatcher.new(nil).
              for(attribute_name).
              with_message(validation_message_key)
            @missing_option = ''
          end

          def description
            "required: #{required}"
          end

          def matches?(subject)
            if submatcher_passes?(subject)
              true
            else
              @missing_option = 'and for the record '

              missing_option <<
                if required
                  'to '
                else
                  'not to '
                end

              missing_option << (
                'fail validation if '\
                ":#{attribute_name} is unset; i.e., either the association "\
                'should have been defined with `required: '\
                "#{required.inspect}`, or there "
              )

              missing_option <<
                if required
                  'should '
                else
                  'should not '
                end

              missing_option << "be a presence validation on :#{attribute_name}"

              false
            end
          end

          private

          attr_reader :attribute_name, :required, :submatcher

          def submatcher_passes?(subject)
            if required
              submatcher.matches?(subject)
            else
              submatcher.does_not_match?(subject)
            end
          end

          def validation_message_key
            :required
          end
        end
      end
    end
  end
end
