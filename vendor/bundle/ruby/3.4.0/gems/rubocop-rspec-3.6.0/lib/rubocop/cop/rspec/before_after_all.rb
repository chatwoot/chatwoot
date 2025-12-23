# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that before/after(:all/:context) isn't being used.
      #
      # @example
      #   # bad - Faster but risk of state leaking between examples
      #   describe MyClass do
      #     before(:all) { Widget.create }
      #     after(:context) { Widget.delete_all }
      #   end
      #
      #   # good - Slower but examples are properly isolated
      #   describe MyClass do
      #     before(:each) { Widget.create }
      #     after(:each) { Widget.delete_all }
      #   end
      #
      class BeforeAfterAll < Base
        MSG = 'Beware of using `%<hook>s` as it may cause state to leak ' \
              'between tests. If you are using `rspec-rails`, and ' \
              '`use_transactional_fixtures` is enabled, then records created ' \
              'in `%<hook>s` are not automatically rolled back.'

        RESTRICT_ON_SEND = Set[:before, :after].freeze

        # @!method before_or_after_all(node)
        def_node_matcher :before_or_after_all, <<~PATTERN
          $(send _ RESTRICT_ON_SEND (sym {:all :context}))
        PATTERN

        def on_send(node)
          before_or_after_all(node) do |hook|
            add_offense(
              node,
              message: format(MSG, hook: hook.source)
            )
          end
        end
      end
    end
  end
end
