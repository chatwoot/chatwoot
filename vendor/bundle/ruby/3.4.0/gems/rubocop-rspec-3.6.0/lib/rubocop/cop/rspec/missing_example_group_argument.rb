# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that the first argument to an example group is not empty.
      #
      # @example
      #   # bad
      #   describe do
      #   end
      #
      #   RSpec.describe do
      #   end
      #
      #   # good
      #   describe TestedClass do
      #   end
      #
      #   describe "A feature example" do
      #   end
      #
      class MissingExampleGroupArgument < Base
        MSG = 'The first argument to `%<method>s` should not be empty.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group?(node)
          return if node.send_node.arguments?

          add_offense(node, message: format(MSG, method: node.method_name))
        end
      end
    end
  end
end
