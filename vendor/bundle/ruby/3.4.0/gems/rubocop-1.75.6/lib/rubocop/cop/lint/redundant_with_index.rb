# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for redundant `with_index`.
      #
      # @example
      #   # bad
      #   ary.each_with_index do |v|
      #     v
      #   end
      #
      #   # good
      #   ary.each do |v|
      #     v
      #   end
      #
      #   # bad
      #   ary.each.with_index do |v|
      #     v
      #   end
      #
      #   # good
      #   ary.each do |v|
      #     v
      #   end
      #
      class RedundantWithIndex < Base
        include RangeHelp
        extend AutoCorrector

        MSG_EACH_WITH_INDEX = 'Use `each` instead of `each_with_index`.'
        MSG_WITH_INDEX = 'Remove redundant `with_index`.'

        # rubocop:disable Metrics/AbcSize
        def on_block(node)
          return unless node.receiver
          return if node.method?(:with_index) && !node.receiver.receiver
          return unless (send = redundant_with_index?(node))

          range = with_index_range(send)

          add_offense(range, message: message(send)) do |corrector|
            if send.method?(:each_with_index)
              corrector.replace(send.loc.selector, 'each')
            else
              corrector.remove(range)
              corrector.remove(send.loc.dot)
            end
          end
        end
        # rubocop:enable Metrics/AbcSize

        alias on_numblock on_block
        alias on_itblock on_block

        private

        # @!method redundant_with_index?(node)
        def_node_matcher :redundant_with_index?, <<~PATTERN
          {
            (block
              $(call _ {:each_with_index :with_index} ...)
              (args (arg _)) ...)
            (numblock
              $(call _ {:each_with_index :with_index} ...) 1 ...)
            (itblock
              $(call _ {:each_with_index :with_index} ...) _ ...)
          }
        PATTERN

        def message(node)
          if node.method?(:each_with_index)
            MSG_EACH_WITH_INDEX
          else
            MSG_WITH_INDEX
          end
        end

        def with_index_range(send)
          range_between(send.loc.selector.begin_pos, send.source_range.end_pos)
        end
      end
    end
  end
end
