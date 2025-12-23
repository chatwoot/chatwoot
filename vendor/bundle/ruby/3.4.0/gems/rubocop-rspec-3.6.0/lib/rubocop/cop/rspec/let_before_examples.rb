# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for `let` definitions that come after an example.
      #
      # @example
      #   # bad
      #   let(:foo) { bar }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   let(:some) { other }
      #
      #   it 'checks what some does' do
      #     expect(some).to be
      #   end
      #
      #   # good
      #   let(:foo) { bar }
      #   let(:some) { other }
      #
      #   it 'checks what foo does' do
      #     expect(foo).to be
      #   end
      #
      #   it 'checks what some does' do
      #     expect(some).to be
      #   end
      class LetBeforeExamples < Base
        extend AutoCorrector

        MSG = 'Move `let` before the examples in the group.'

        # @!method example_or_group?(node)
        def_node_matcher :example_or_group?, <<~PATTERN
          {
            (block (send nil? {#ExampleGroups.all #Examples.all} ...) ...)
            (send nil? #Includes.examples ...)
          }
        PATTERN

        # @!method include_examples?(node)
        def_node_matcher :include_examples?, <<~PATTERN
          {
            (block (send nil? :include_examples ...) ...)
            (send nil? :include_examples ...)
          }
        PATTERN

        def self.autocorrect_incompatible_with
          [RSpec::ScatteredLet]
        end

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group_with_body?(node)

          check_let_declarations(node.body) if multiline_block?(node.body)
        end

        private

        def example_group_with_include_examples?(body)
          body.children.any? { |sibling| include_examples?(sibling) }
        end

        def multiline_block?(block)
          block.begin_type?
        end

        def check_let_declarations(node)
          first_example = find_first_example(node)
          return unless first_example

          correct = !example_group_with_include_examples?(node)

          first_example.right_siblings.each do |sibling|
            next unless let?(sibling)

            add_offense(sibling) do |corrector|
              autocorrect(corrector, sibling, first_example) if correct
            end
          end
        end

        def find_first_example(node)
          node.children.find { |sibling| example_or_group?(sibling) }
        end

        def autocorrect(corrector, node, first_example)
          RuboCop::RSpec::Corrector::MoveNode.new(
            node, corrector, processed_source
          ).move_before(first_example)
        end
      end
    end
  end
end
