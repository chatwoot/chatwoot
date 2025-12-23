# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks for pending or skipped examples without reason.
      #
      # @example
      #   # bad
      #   pending 'does something' do
      #   end
      #
      #   # bad
      #   it 'does something', :pending do
      #   end
      #
      #   # bad
      #   it 'does something' do
      #     pending
      #   end
      #
      #   # bad
      #   xdescribe 'something' do
      #   end
      #
      #   # bad
      #   skip 'does something' do
      #   end
      #
      #   # bad
      #   it 'does something', :skip do
      #   end
      #
      #   # bad
      #   it 'does something' do
      #     skip
      #   end
      #
      #   # bad
      #   it 'does something'
      #
      #   # good
      #   it 'does something' do
      #     pending 'reason'
      #   end
      #
      #   # good
      #   it 'does something' do
      #     skip 'reason'
      #   end
      #
      #   # good
      #   it 'does something', pending: 'reason' do
      #   end
      #
      #   # good
      #   it 'does something', skip: 'reason' do
      #   end
      class PendingWithoutReason < Base
        MSG = 'Give the reason for pending or skip.'

        # @!method skipped_in_example?(node)
        def_node_matcher :skipped_in_example?, <<~PATTERN
          {
            (send nil? ${#Examples.skipped #Examples.pending})
            (any_block (send nil? ${#Examples.skipped}) ...)
          }
        PATTERN

        # @!method skipped_by_example_method?(node)
        def_node_matcher :skipped_by_example_method?, <<~PATTERN
          (send nil? ${#Examples.skipped #Examples.pending})
        PATTERN

        # @!method skipped_by_example_method_with_block?(node)
        def_node_matcher :skipped_by_example_method_with_block?, <<~PATTERN
          (any_block (send nil? ${#Examples.skipped #Examples.pending} ...) ...)
        PATTERN

        # @!method metadata_without_reason?(node)
        def_node_matcher :metadata_without_reason?, <<~PATTERN
          (send #rspec?
            {#ExampleGroups.all #Examples.all} ...
            {
              <(sym ${:pending :skip}) ...>
              (hash <(pair (sym ${:pending :skip}) true) ...>)
            }
          )
        PATTERN

        # @!method skipped_by_example_group_method?(node)
        def_node_matcher :skipped_by_example_group_method?, <<~PATTERN
          (send #rspec? ${#ExampleGroups.skipped} ...)
        PATTERN

        def on_send(node)
          on_pending_by_metadata(node)
          return unless (parent = parent_node(node))

          if spec_group?(parent) || block_node_example_group?(node)
            on_skipped_by_example_method(node)
            on_skipped_by_example_group_method(node)
          elsif example?(parent)
            on_skipped_by_in_example_method(node)
          end
        end

        private

        def parent_node(node)
          node_or_block = node.block_node || node
          return unless (parent = node_or_block.parent)

          parent.begin_type? && parent.parent ? parent.parent : parent
        end

        def block_node_example_group?(node)
          node.block_node &&
            example_group?(node.block_node) &&
            explicit_rspec?(node.receiver)
        end

        def on_skipped_by_in_example_method(node)
          skipped_in_example?(node) do |pending|
            add_offense(node, message: "Give the reason for #{pending}.")
          end
        end

        def on_pending_by_metadata(node)
          metadata_without_reason?(node) do |pending|
            add_offense(node, message: "Give the reason for #{pending}.")
          end
        end

        def on_skipped_by_example_method(node)
          skipped_by_example_method?(node) do |pending|
            add_offense(node, message: "Give the reason for #{pending}.")
          end

          skipped_by_example_method_with_block?(node.parent) do |pending|
            add_offense(node, message: "Give the reason for #{pending}.")
          end
        end

        def on_skipped_by_example_group_method(node)
          skipped_by_example_group_method?(node) do
            add_offense(node, message: 'Give the reason for skip.')
          end
        end
      end
    end
  end
end
