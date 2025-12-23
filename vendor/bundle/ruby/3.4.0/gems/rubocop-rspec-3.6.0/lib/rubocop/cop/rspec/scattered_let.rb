# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for let scattered across the example group.
      #
      # Group lets together
      #
      # @example
      #   # bad
      #   describe Foo do
      #     let(:foo) { 1 }
      #     subject { Foo }
      #     let(:bar) { 2 }
      #     before { prepare }
      #     let!(:baz) { 3 }
      #   end
      #
      #   # good
      #   describe Foo do
      #     subject { Foo }
      #     before { prepare }
      #     let(:foo) { 1 }
      #     let(:bar) { 2 }
      #     let!(:baz) { 3 }
      #   end
      #
      class ScatteredLet < Base
        extend AutoCorrector

        MSG = 'Group all let/let! blocks in the example group together.'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_group_with_body?(node)

          check_let_declarations(node.body)
        end

        private

        def check_let_declarations(body)
          lets = body.each_child_node.select { |node| let?(node) }

          first_let = lets.first
          lets.each_with_index do |node, idx|
            next if node.sibling_index == first_let.sibling_index + idx

            add_offense(node) do |corrector|
              RuboCop::RSpec::Corrector::MoveNode.new(
                node, corrector, processed_source
              ).move_after(first_let)
            end
          end
        end
      end
    end
  end
end
