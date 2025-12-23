module Shoulda
  module Matchers
    module ActionController
      # @private
      class SetSessionOrFlashMatcher
        def initialize(store)
          @store = store
        end

        def in_context(context)
          @context = context
          self
        end

        def [](key)
          @key = key
          self
        end

        def to(expected_value = nil, &block)
          if block
            unless context_set?
              message = 'When specifying a value as a block, a context must be'\
                ' specified beforehand,'\
                " e.g., #{store.name}.in_context(context).to { ... }"
              raise ArgumentError, message
            end

            @expected_value = context.instance_eval(&block)
          else
            @expected_value = expected_value
          end

          self
        end

        def description
          "should #{expectation_description}"
        end

        def matches?(controller)
          @controller = store.controller = controller
          !store.empty? && key_matches? && expected_value_matches?
        end

        def failure_message
          "Expected #{controller.class} to #{expectation_description},"\
          ' but it did not'
        end
        alias_method :failure_message_for_should, :failure_message

        def failure_message_when_negated
          "Expected #{controller.class} not to #{expectation_description},"\
          ' but it did'
        end
        alias_method :failure_message_for_should_not,
          :failure_message_when_negated

        protected

        attr_reader :store, :context, :key, :expected_value, :controller

        private

        def context_set?
          defined?(@context)
        end

        def key_set?
          defined?(@key)
        end

        def expected_value_set?
          defined?(@expected_value)
        end

        def key_matches?
          !key_set? || store.has_key?(key)
        end

        def expected_value_matches?
          !expected_value_set? || store.has_value?(expected_value)
        end

        def expectation_description
          string = 'set'

          string <<
            if key_set?
              " #{store.name}[#{key.inspect}]"
            else
              " any key in #{store.name}"
            end

          if expected_value_set?
            string <<
              if expected_value.is_a?(Regexp)
                " to a value matching #{expected_value.inspect}"
              else
                " to #{expected_value.inspect}"
              end
          end

          string
        end
      end
    end
  end
end
