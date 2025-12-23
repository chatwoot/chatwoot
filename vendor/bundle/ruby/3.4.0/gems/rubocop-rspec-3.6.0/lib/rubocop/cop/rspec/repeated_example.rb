# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for repeated examples within example groups.
      #
      # @example
      #
      #   it 'is valid' do
      #     expect(user).to be_valid
      #   end
      #
      #   it 'validates the user' do
      #     expect(user).to be_valid
      #   end
      #
      class RepeatedExample < Base
        MSG = "Don't repeat examples within an example group."

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group?(node)

          repeated_examples(node).each do |repeated_example|
            add_offense(repeated_example)
          end
        end

        private

        def repeated_examples(node)
          RuboCop::RSpec::ExampleGroup.new(node)
            .examples
            .group_by { |example| example_signature(example) }
            .values
            .reject(&:one?)
            .flatten
            .map(&:to_node)
        end

        def example_signature(example)
          key_parts = [example.metadata, example.implementation]

          if example.definition.method?(:its)
            key_parts << example.definition.arguments
          end

          key_parts
        end
      end
    end
  end
end
