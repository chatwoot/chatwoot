# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for places where multiple consecutive loops over the same data
      # can be combined into a single loop. It is very likely that combining them
      # will make the code more efficient and more concise.
      #
      # NOTE: Autocorrection is not applied when the block variable names differ in separate loops,
      # as it is impossible to determine which variable name should be prioritized.
      #
      # @safety
      #   The cop is unsafe, because the first loop might modify state that the
      #   second loop depends on; these two aren't combinable.
      #
      # @example
      #   # bad
      #   def method
      #     items.each do |item|
      #       do_something(item)
      #     end
      #
      #     items.each do |item|
      #       do_something_else(item)
      #     end
      #   end
      #
      #   # good
      #   def method
      #     items.each do |item|
      #       do_something(item)
      #       do_something_else(item)
      #     end
      #   end
      #
      #   # bad
      #   def method
      #     for item in items do
      #       do_something(item)
      #     end
      #
      #     for item in items do
      #       do_something_else(item)
      #     end
      #   end
      #
      #   # good
      #   def method
      #     for item in items do
      #       do_something(item)
      #       do_something_else(item)
      #     end
      #   end
      #
      #   # good
      #   def method
      #     each_slice(2) { |slice| do_something(slice) }
      #     each_slice(3) { |slice| do_something(slice) }
      #   end
      #
      class CombinableLoops < Base
        extend AutoCorrector

        MSG = 'Combine this loop with the previous loop.'

        # rubocop:disable Metrics/CyclomaticComplexity
        def on_block(node)
          return unless node.parent&.begin_type?
          return unless collection_looping_method?(node)
          return unless same_collection_looping_block?(node, node.left_sibling)
          return unless node.body && node.left_sibling.body

          add_offense(node) do |corrector|
            next unless node.arguments == node.left_sibling.arguments

            combine_with_left_sibling(corrector, node)
          end
        end
        # rubocop:enable Metrics/CyclomaticComplexity

        alias on_numblock on_block
        alias on_itblock on_block

        def on_for(node)
          return unless node.parent&.begin_type?
          return unless same_collection_looping_for?(node, node.left_sibling)

          add_offense(node) do |corrector|
            combine_with_left_sibling(corrector, node)
          end
        end

        private

        def collection_looping_method?(node)
          method_name = node.method_name
          method_name.start_with?('each') || method_name.end_with?('_each')
        end

        def same_collection_looping_block?(node, sibling)
          return false if sibling.nil? || !sibling.any_block_type?

          sibling.method?(node.method_name) &&
            sibling.receiver == node.receiver &&
            sibling.send_node.arguments == node.send_node.arguments
        end

        def same_collection_looping_for?(node, sibling)
          sibling&.for_type? && node.collection == sibling.collection
        end

        def combine_with_left_sibling(corrector, node)
          corrector.remove(node.left_sibling.body.source_range.end.join(node.left_sibling.loc.end))
          corrector.remove(node.source_range.begin.join(node.body.source_range.begin))

          correct_end_of_block(corrector, node)
        end

        def correct_end_of_block(corrector, node)
          return unless node.left_sibling.respond_to?(:braces?)
          return if node.right_sibling&.any_block_type?

          end_of_block = node.left_sibling.braces? ? '}' : ' end'
          corrector.remove(node.loc.end)
          corrector.insert_before(node.source_range.end, end_of_block)
        end
      end
    end
  end
end
