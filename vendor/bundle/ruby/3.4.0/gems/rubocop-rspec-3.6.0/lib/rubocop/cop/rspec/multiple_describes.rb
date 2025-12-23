# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for multiple top-level example groups.
      #
      # Multiple descriptions for the same class or module should either
      # be nested or separated into different test files.
      #
      # @example
      #   # bad
      #   describe MyClass, '.do_something' do
      #   end
      #   describe MyClass, '.do_something_else' do
      #   end
      #
      #   # good
      #   describe MyClass do
      #     describe '.do_something' do
      #     end
      #     describe '.do_something_else' do
      #     end
      #   end
      #
      class MultipleDescribes < Base
        include TopLevelGroup

        MSG = 'Do not use multiple top-level example groups - try to nest them.'

        def on_top_level_group(node)
          top_level_example_groups =
            top_level_groups.select { |group| example_group?(group) }

          return if top_level_example_groups.one?
          return unless top_level_example_groups.first.equal?(node)

          add_offense(node.send_node)
        end
      end
    end
  end
end
