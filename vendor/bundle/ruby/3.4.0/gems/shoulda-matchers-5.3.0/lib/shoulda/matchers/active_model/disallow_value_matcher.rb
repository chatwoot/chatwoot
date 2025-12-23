require 'forwardable'

module Shoulda
  module Matchers
    module ActiveModel
      # @private
      class DisallowValueMatcher
        extend Forwardable

        def_delegators(
          :allow_matcher,
          :_after_setting_value,
          :attribute_changed_value_message=,
          :attribute_to_set,
          :description,
          :expects_strict?,
          :failure_message_preface,
          :failure_message_preface=,
          :ignore_interference_by_writer,
          :last_attribute_setter_used,
          :last_value_set,
          :model,
          :simple_description,
          :values_to_preset=,
        )

        def initialize(value)
          @allow_matcher = AllowValueMatcher.new(value)
        end

        def matches?(subject)
          allow_matcher.does_not_match?(subject)
        end

        def does_not_match?(subject)
          allow_matcher.matches?(subject)
        end

        def for(attribute)
          allow_matcher.for(attribute)
          self
        end

        def on(context)
          allow_matcher.on(context)
          self
        end

        def with_message(message, options = {})
          allow_matcher.with_message(message, options)
          self
        end

        def strict(strict = true)
          allow_matcher.strict(strict)
          self
        end

        def ignoring_interference_by_writer(value = :always)
          allow_matcher.ignoring_interference_by_writer(value)
          self
        end

        def failure_message
          allow_matcher.failure_message_when_negated
        end

        def failure_message_when_negated
          allow_matcher.failure_message
        end

        protected

        attr_reader :allow_matcher
      end
    end
  end
end
