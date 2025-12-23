module Shoulda
  module Matchers
    module ActiveModel
      # @private
      class ValidationMessageFinder
        include Helpers

        def initialize(instance, attribute, context = nil)
          @instance = instance
          @attribute = attribute
          @context = context
        end

        def allow_description(allowed_values)
          "allow #{@attribute} to be set to #{allowed_values}"
        end

        def expected_message_from(attribute_message)
          attribute_message
        end

        def has_messages?
          errors.present?
        end

        def source_description
          'errors'
        end

        def messages_description
          if errors.empty?
            ' no errors'
          else
            " errors:\n#{pretty_error_messages(validated_instance)}"
          end
        end

        def messages
          Array(messages_for_attribute)
        end

        private

        def messages_for_attribute
          errors[@attribute]
        end

        def errors
          validated_instance.errors
        end

        def validated_instance
          @_validated_instance ||= validate_instance
        end

        def validate_instance
          @instance.valid?(*@context)
          @instance
        end
      end
    end
  end
end
