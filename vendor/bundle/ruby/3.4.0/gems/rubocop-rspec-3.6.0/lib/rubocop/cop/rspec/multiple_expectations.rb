# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks if examples contain too many `expect` calls.
      #
      # @see http://betterspecs.org/#single Single expectation test
      #
      # This cop is configurable using the `Max` option
      # and works with `--auto-gen-config`.
      #
      # @example
      #   # bad
      #   describe UserCreator do
      #     it 'builds a user' do
      #       expect(user.name).to eq("John")
      #       expect(user.age).to eq(22)
      #     end
      #   end
      #
      #   # good
      #   describe UserCreator do
      #     it 'sets the users name' do
      #       expect(user.name).to eq("John")
      #     end
      #
      #     it 'sets the users age' do
      #       expect(user.age).to eq(22)
      #     end
      #   end
      #
      # @example `aggregate_failures: true` (default)
      #   # good - the cop ignores when RSpec aggregates failures
      #   describe UserCreator do
      #     it 'builds a user', :aggregate_failures do
      #       expect(user.name).to eq("John")
      #       expect(user.age).to eq(22)
      #     end
      #   end
      #
      # @example `aggregate_failures: false`
      #   # Detected as an offense
      #   describe UserCreator do
      #     it 'builds a user', aggregate_failures: false do
      #       expect(user.name).to eq("John")
      #       expect(user.age).to eq(22)
      #     end
      #   end
      #
      # @example `Max: 1` (default)
      #   # bad
      #   describe UserCreator do
      #     it 'builds a user' do
      #       expect(user.name).to eq("John")
      #       expect(user.age).to eq(22)
      #     end
      #   end
      #
      # @example `Max: 2`
      #   # good
      #   describe UserCreator do
      #     it 'builds a user' do
      #       expect(user.name).to eq("John")
      #       expect(user.age).to eq(22)
      #     end
      #   end
      #
      class MultipleExpectations < Base
        MSG = 'Example has too many expectations [%<total>d/%<max>d].'

        ANYTHING = ->(_node) { true }
        TRUE_NODE = lambda(&:true_type?)

        exclude_limit 'Max'

        # @!method aggregate_failures?(node)
        def_node_matcher :aggregate_failures?, <<~PATTERN
          (block {
              (send _ _ <(sym :aggregate_failures) ...>)
              (send _ _ ... (hash <(pair (sym :aggregate_failures) %1) ...>))
            } ...)
        PATTERN

        # @!method expect?(node)
        def_node_matcher :expect?, '(send nil? #Expectations.all ...)'

        # @!method aggregate_failures_block?(node)
        def_node_matcher :aggregate_failures_block?, <<~PATTERN
          (block (send nil? :aggregate_failures ...) ...)
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless example?(node)

          return if example_with_aggregate_failures?(node)

          expectations_count = to_enum(:find_expectation, node).count

          return if expectations_count <= max_expectations

          self.max = expectations_count

          flag_example(node, expectation_count: expectations_count)
        end

        private

        def example_with_aggregate_failures?(example_node)
          node_with_aggregate_failures = find_aggregate_failures(example_node)
          return false unless node_with_aggregate_failures

          aggregate_failures?(node_with_aggregate_failures, TRUE_NODE)
        end

        def find_aggregate_failures(example_node)
          example_node.send_node.each_ancestor(:block)
            .find { |block_node| aggregate_failures?(block_node, ANYTHING) }
        end

        def find_expectation(node, &block)
          yield if expect?(node) || aggregate_failures_block?(node)

          # do not search inside of aggregate_failures block
          return if aggregate_failures_block?(node)

          node.each_child_node do |child|
            find_expectation(child, &block)
          end
        end

        def flag_example(node, expectation_count:)
          add_offense(
            node.send_node,
            message: format(
              MSG,
              total: expectation_count,
              max: max_expectations
            )
          )
        end

        def max_expectations
          Integer(cop_config.fetch('Max', 1))
        end
      end
    end
  end
end
