# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Do not use `expect` in hooks such as `before`.
      #
      # @example
      #   # bad
      #   before do
      #     expect(something).to eq 'foo'
      #   end
      #
      #   # bad
      #   after do
      #     expect_any_instance_of(Something).to receive(:foo)
      #   end
      #
      #   # good
      #   it do
      #     expect(something).to eq 'foo'
      #   end
      #
      class ExpectInHook < Base
        MSG = 'Do not use `%<expect>s` in `%<hook>s` hook'

        # @!method expectation(node)
        def_node_search :expectation, '(send nil? #Expectations.all ...)'

        def on_block(node)
          return unless hook?(node)
          return if node.body.nil?

          expectation(node.body) do |expect|
            add_offense(expect.loc.selector,
                        message: message(expect, node))
          end
        end

        alias on_numblock on_block

        private

        def message(expect, hook)
          format(MSG, expect: expect.method_name, hook: hook.method_name)
        end
      end
    end
  end
end
