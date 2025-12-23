# frozen_string_literal: true

module RuboCop
  module Cop
    module InternalAffairs
      # Checks that cops are not tested using `described_class::MSG`.
      #
      # @example
      #
      #     # bad
      #     expect(cop.messages).to eq([described_class::MSG])
      #
      #     # good
      #     expect(cop.messages).to eq(['Do not write bad code like that.'])
      #
      class UselessMessageAssertion < Base
        MSG = 'Do not specify cop behavior using `described_class::MSG`.'

        # @!method described_class_msg(node)
        def_node_search :described_class_msg, <<~PATTERN
          (const (send nil? :described_class) :MSG)
        PATTERN

        # @!method rspec_expectation_on_msg?(node)
        def_node_matcher :rspec_expectation_on_msg?, <<~PATTERN
          (send (send nil? :expect #contains_described_class_msg?) :to ...)
        PATTERN

        def on_new_investigation
          return if processed_source.blank?

          assertions_using_described_class_msg.each { |node| add_offense(node) }
        end

        private

        def contains_described_class_msg?(node)
          described_class_msg(node).any?
        end

        def assertions_using_described_class_msg
          described_class_msg(processed_source.ast).reject do |node|
            node.ancestors.any? { |ancestor| rspec_expectation_on_msg?(ancestor) }
          end
        end
      end
    end
  end
end
