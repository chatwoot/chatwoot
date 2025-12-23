module Shoulda
  module Matchers
    module ActiveModel
      # @private
      class ValidationMatcher
        include Qualifiers::IgnoringInterferenceByWriter

        def initialize(attribute)
          super
          @attribute = attribute
          @expects_strict = false
          @subject = nil
          @last_submatcher_run = nil
          @expected_message = nil
          @expects_custom_validation_message = false
        end

        def description
          ValidationMatcher::BuildDescription.call(self, simple_description)
        end

        def on(context)
          @context = context
          self
        end

        def allow_blank
          options[:allow_blank] = true
          self
        end

        def strict
          @expects_strict = true
          self
        end

        def expects_strict?
          @expects_strict
        end

        def with_message(expected_message)
          if expected_message
            @expects_custom_validation_message = true
            @expected_message = expected_message
          end

          self
        end

        def expects_custom_validation_message?
          @expects_custom_validation_message
        end

        def matches?(subject)
          @subject = subject
          false
        end

        def does_not_match?(subject)
          @subject = subject
          true
        end

        def failure_message
          overall_failure_message.dup.tap do |message|
            if failure_reason.present?
              message << "\n"
              message << Shoulda::Matchers.word_wrap(
                failure_reason,
                indent: 2,
              )
            end
          end
        end

        def failure_message_when_negated
          overall_failure_message_when_negated.dup.tap do |message|
            if failure_reason.present?
              message << "\n"
              message << Shoulda::Matchers.word_wrap(
                failure_reason,
                indent: 2,
              )
            end
          end
        end

        protected

        attr_reader :attribute, :context, :subject, :last_submatcher_run

        def model
          subject.class
        end

        def allows_value_of(value, message = nil, &block)
          matcher = allow_value_matcher(value, message, &block)
          run_allow_or_disallow_matcher(matcher)
        end

        def disallows_value_of(value, message = nil, &block)
          matcher = disallow_value_matcher(value, message, &block)
          run_allow_or_disallow_matcher(matcher)
        end

        def allow_value_matcher(value, message = nil, &block)
          build_allow_or_disallow_value_matcher(
            matcher_class: AllowValueMatcher,
            value: value,
            message: message,
            &block
          )
        end

        def disallow_value_matcher(value, message = nil, &block)
          build_allow_or_disallow_value_matcher(
            matcher_class: DisallowValueMatcher,
            value: value,
            message: message,
            &block
          )
        end

        def allow_blank_matches?
          !expects_to_allow_blank? ||
            blank_values.all? { |value| allows_value_of(value) }
        end

        def allow_blank_does_not_match?
          expects_to_allow_blank? &&
            blank_values.all? { |value| disallows_value_of(value) }
        end

        private

        attr_reader :options

        def overall_failure_message
          Shoulda::Matchers.word_wrap(
            "Expected #{model.name} to #{description}, but this could not be "\
            'proved.',
          )
        end

        def overall_failure_message_when_negated
          Shoulda::Matchers.word_wrap(
            "Expected #{model.name} not to #{description}, but this could "\
            'not be proved.',
          )
        end

        def failure_reason
          last_submatcher_run.try(:failure_message)
        end

        def failure_reason_when_negated
          last_submatcher_run.try(:failure_message_when_negated)
        end

        def build_allow_or_disallow_value_matcher(args)
          matcher_class = args.fetch(:matcher_class)
          value = args.fetch(:value)
          message = args[:message]

          matcher = matcher_class.new(value).
            for(attribute).
            with_message(message).
            on(context).
            strict(expects_strict?).
            ignoring_interference_by_writer(ignore_interference_by_writer)

          yield matcher if block_given?

          matcher
        end

        def run_allow_or_disallow_matcher(matcher)
          @last_submatcher_run = matcher
          matcher.matches?(subject)
        end

        def expects_to_allow_blank?
          options[:allow_blank]
        end

        def blank_values
          ['', ' ', "\n", "\r", "\t", "\f"]
        end
      end
    end
  end
end
