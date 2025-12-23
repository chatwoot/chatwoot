# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for proper shared_context and shared_examples usage.
      #
      # If there are no examples defined, use shared_context.
      # If there is no setup defined, use shared_examples.
      #
      # @example
      #   # bad
      #   RSpec.shared_context 'only examples here' do
      #     it 'does x' do
      #     end
      #
      #     it 'does y' do
      #     end
      #   end
      #
      #   # good
      #   RSpec.shared_examples 'only examples here' do
      #     it 'does x' do
      #     end
      #
      #     it 'does y' do
      #     end
      #   end
      #
      # @example
      #   # bad
      #   RSpec.shared_examples 'only setup here' do
      #     subject(:foo) { :bar }
      #
      #     let(:baz) { :bazz }
      #
      #     before do
      #       something
      #     end
      #   end
      #
      #   # good
      #   RSpec.shared_context 'only setup here' do
      #     subject(:foo) { :bar }
      #
      #     let(:baz) { :bazz }
      #
      #     before do
      #       something
      #     end
      #   end
      #
      class SharedContext < Base
        extend AutoCorrector

        MSG_EXAMPLES = "Use `shared_examples` when you don't define context."
        MSG_CONTEXT  = "Use `shared_context` when you don't define examples."

        # @!method examples?(node)
        def_node_search :examples?, <<~PATTERN
          (send nil? {#Includes.examples #Examples.all} ...)
        PATTERN

        # @!method context?(node)
        def_node_search :context?, <<~PATTERN
          (send nil?
            {#Subjects.all #Helpers.all #Includes.context #Hooks.all} ...
          )
        PATTERN

        # @!method shared_context(node)
        def_node_matcher :shared_context, <<~PATTERN
          (block (send #rspec? #SharedGroups.context ...) ...)
        PATTERN

        # @!method shared_example(node)
        def_node_matcher :shared_example, <<~PATTERN
          (block (send #rspec? #SharedGroups.examples ...) ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          context_with_only_examples(node) do
            add_offense(node.send_node, message: MSG_EXAMPLES) do |corrector|
              corrector.replace(node.send_node.loc.selector, 'shared_examples')
            end
          end

          examples_with_only_context(node) do
            add_offense(node.send_node, message: MSG_CONTEXT) do |corrector|
              corrector.replace(node.send_node.loc.selector, 'shared_context')
            end
          end
        end

        private

        def context_with_only_examples(node)
          shared_context(node) { yield if examples?(node) && !context?(node) }
        end

        def examples_with_only_context(node)
          shared_example(node) { yield if context?(node) && !examples?(node) }
        end
      end
    end
  end
end
