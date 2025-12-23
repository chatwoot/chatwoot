# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Avoid opening modules and defining specs within them.
      #
      # @example
      #   # bad
      #   module MyModule
      #     RSpec.describe MyClass do
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe MyModule::MyClass do
      #     # ...
      #   end
      #
      # @see https://github.com/rubocop/rubocop-rspec/issues/735
      class DescribedClassModuleWrapping < Base
        MSG = 'Avoid opening modules and defining specs within them.'

        # @!method include_rspec_blocks?(node)
        def_node_search :include_rspec_blocks?, <<~PATTERN
          (any_block (send #explicit_rspec? #ExampleGroups.all ...) ...)
        PATTERN

        def on_module(node)
          return unless include_rspec_blocks?(node)

          add_offense(node)
        end
      end
    end
  end
end
