module Shoulda
  module Matchers
    module ActiveModel
      # @private
      class Validator
        include Helpers

        def initialize(record, attribute, options = {})
          @record = record
          @attribute = attribute
          @context = options[:context]
          @expects_strict = options[:expects_strict]
          @expected_message = options[:expected_message]

          @_validation_result = nil
          @captured_validation_exception = false
          @captured_range_error = false
        end

        def call
          !messages_match? && !captured_range_error?
        end

        def has_messages?
          messages.any?
        end

        def captured_validation_exception?
          @captured_validation_exception
        end

        def type_of_message_matched?
          expects_strict? == captured_validation_exception?
        end

        def all_formatted_validation_error_messages
          format_validation_errors(all_validation_errors)
        end

        def validation_exception_message
          validation_result[:validation_exception_message]
        end

        protected

        attr_reader :attribute, :context, :record

        private

        def expects_strict?
          @expects_strict
        end

        def messages_match?
          has_messages? &&
            type_of_message_matched? &&
            matched_messages.compact.any?
        end

        def messages
          if expects_strict?
            [validation_exception_message]
          else
            validation_error_messages
          end
        end

        def matched_messages
          if @expected_message
            messages.grep(@expected_message)
          else
            messages
          end
        end

        def captured_range_error?
          !!@captured_range_error
        end

        def all_validation_errors
          validation_result[:all_validation_errors]
        end

        def validation_error_messages
          validation_result[:validation_error_messages]
        end

        def validation_result
          @_validation_result ||= perform_validation
        end

        def perform_validation
          if context
            record.valid?(context)
          else
            record.valid?
          end

          all_validation_errors = record.errors.dup

          validation_error_messages = record.errors[attribute]

          {
            all_validation_errors: all_validation_errors,
            validation_error_messages: validation_error_messages,
            validation_exception_message: nil,
          }
        rescue ::ActiveModel::StrictValidationFailed => e
          @captured_validation_exception = true
          {
            all_validation_errors: nil,
            validation_error_messages: [],
            validation_exception_message: e.message,
          }
        end
      end
    end
  end
end
