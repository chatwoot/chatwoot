# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Check that implicit block expectation syntax is not used.
      #
      # Prefer using explicit block expectations.
      #
      # @example
      #   # bad
      #   subject { -> { do_something } }
      #   it { is_expected.to change(something).to(new_value) }
      #
      #   # good
      #   it 'changes something to a new value' do
      #     expect { do_something }.to change(something).to(new_value)
      #   end
      #
      class ImplicitBlockExpectation < Base
        MSG = 'Avoid implicit block expectations.'
        RESTRICT_ON_SEND = %i[is_expected should should_not].freeze

        # @!method lambda?(node)
        def_node_matcher :lambda?, <<~PATTERN
          {
            (send (const nil? :Proc) :new)
            (send nil? {:proc :lambda})
          }
        PATTERN

        # @!method lambda_subject?(node)
        def_node_matcher :lambda_subject?, '(block #lambda? ...)'

        # @!method implicit_expect(node)
        def_node_matcher :implicit_expect, <<~PATTERN
          $(send nil? {:is_expected :should :should_not} ...)
        PATTERN

        def on_send(node)
          implicit_expect(node) do |implicit_expect|
            subject = nearest_subject(implicit_expect)
            add_offense(implicit_expect) if lambda_subject?(subject&.body)
          end
        end

        private

        def nearest_subject(node)
          node
            .each_ancestor(:block)
            .lazy
            .select { |block_node| multi_statement_example_group?(block_node) }
            .map { |block_node| find_subject(block_node) }
            .find(&:itself)
        end

        def multi_statement_example_group?(node)
          example_group_with_body?(node) && node.body.begin_type?
        end

        def find_subject(block_node)
          block_node.body.child_nodes.find { |send_node| subject?(send_node) }
        end
      end
    end
  end
end
