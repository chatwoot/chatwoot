# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Description should be descriptive.
      #
      # If example group or example contains only `execute string`, numbers
      # and regular expressions, the description is not clear.
      #
      # @example
      #   # bad
      #   describe `time` do
      #    # ...
      #   end
      #
      #   # bad
      #   context /when foo/ do
      #     # ...
      #   end
      #
      #   # bad
      #   it 10000 do
      #     # ...
      #   end
      #
      #   # good
      #   describe Foo do
      #     # ...
      #   end
      #
      #   # good
      #   describe '#foo' do
      #     # ...
      #   end
      #
      #   # good
      #   context "when #{foo} is bar" do
      #     # ...
      #   end
      #
      #   # good
      #   it 'does something' do
      #     # ...
      #   end
      #
      class UndescriptiveLiteralsDescription < Base
        MSG = 'Description should be descriptive.'

        # @!method example_groups_or_example?(node)
        def_node_matcher :example_groups_or_example?, <<~PATTERN
          (block (send #rspec? {#ExampleGroups.all #Examples.all} $_) ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          example_groups_or_example?(node) do |arg|
            add_offense(arg) if offense?(arg)
          end
        end

        private

        def offense?(node)
          %i[xstr int regexp].include?(node.type)
        end
      end
    end
  end
end
