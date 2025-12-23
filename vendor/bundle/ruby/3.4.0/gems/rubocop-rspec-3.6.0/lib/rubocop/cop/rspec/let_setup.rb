# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks unreferenced `let!` calls being used for test setup.
      #
      # @example
      #   # bad
      #   let!(:my_widget) { create(:widget) }
      #
      #   it 'counts widgets' do
      #     expect(Widget.count).to eq(1)
      #   end
      #
      #   # good
      #   it 'counts widgets' do
      #     create(:widget)
      #     expect(Widget.count).to eq(1)
      #   end
      #
      #   # good
      #   before { create(:widget) }
      #
      #   it 'counts widgets' do
      #     expect(Widget.count).to eq(1)
      #   end
      class LetSetup < Base
        MSG = 'Do not use `let!` to setup objects not referenced in tests.'

        # @!method example_or_shared_group_or_including?(node)
        def_node_matcher :example_or_shared_group_or_including?, <<~PATTERN
          (block {
            (send #rspec? {#SharedGroups.all #ExampleGroups.all} ...)
            (send nil? #Includes.all ...)
          } ...)
        PATTERN

        # @!method let_bang(node)
        def_node_matcher :let_bang, <<~PATTERN
          {
            (block $(send nil? :let! {(sym $_) (str $_)}) ...)
            $(send nil? :let! {(sym $_) (str $_)} block_pass)
          }
        PATTERN

        # @!method method_called?(node)
        def_node_search :method_called?, '(send nil? %)'

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example_or_shared_group_or_including?(node)

          unused_let_bang(node) do |let|
            add_offense(let)
          end
        end

        private

        def unused_let_bang(node)
          child_let_bang(node) do |method_send, method_name|
            yield(method_send) unless method_called?(node, method_name.to_sym)
          end
        end

        def child_let_bang(node, &block)
          RuboCop::RSpec::ExampleGroup.new(node).lets.each do |let|
            let_bang(let, &block)
          end
        end
      end
    end
  end
end
