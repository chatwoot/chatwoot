# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check for repeated description strings in example groups.
      #
      # @example
      #   # bad
      #   RSpec.describe User do
      #     it 'is valid' do
      #       # ...
      #     end
      #
      #     it 'is valid' do
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe User do
      #     it 'is valid when first and last name are present' do
      #       # ...
      #     end
      #
      #     it 'is valid when last name only is present' do
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   RSpec.describe User do
      #     it 'is valid' do
      #       # ...
      #     end
      #
      #     it 'is valid', :flag do
      #       # ...
      #     end
      #   end
      #
      class RepeatedDescription < Base
        MSG = "Don't repeat descriptions within an example group."

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group?(node)

          repeated_descriptions(node).each do |description|
            add_offense(description)
          end

          repeated_its(node).each do |its|
            add_offense(its)
          end
        end

        private

        # Select examples in the current scope with repeated description strings
        def repeated_descriptions(node)
          grouped_examples =
            RuboCop::RSpec::ExampleGroup.new(node)
              .examples
              .reject { |n| n.definition.method?(:its) }
              .group_by { |example| example_signature(example) }

          grouped_examples
            .select { |signatures, group| signatures.any? && group.size > 1 }
            .values
            .flatten
            .map(&:definition)
        end

        def repeated_its(node)
          grouped_its =
            RuboCop::RSpec::ExampleGroup.new(node)
              .examples
              .select { |n| n.definition.method?(:its) }
              .group_by { |example| its_signature(example) }

          grouped_its
            .select { |signatures, group| signatures.any? && group.size > 1 }
            .values
            .flatten
            .map(&:to_node)
        end

        def example_signature(example)
          [example.metadata, example.doc_string]
        end

        def its_signature(example)
          [example.doc_string, example]
        end
      end
    end
  end
end
