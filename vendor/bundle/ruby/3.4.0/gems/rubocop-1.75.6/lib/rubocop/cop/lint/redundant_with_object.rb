# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for redundant `with_object`.
      #
      # @example
      #   # bad
      #   ary.each_with_object([]) do |v|
      #     v
      #   end
      #
      #   # good
      #   ary.each do |v|
      #     v
      #   end
      #
      #   # bad
      #   ary.each.with_object([]) do |v|
      #     v
      #   end
      #
      #   # good
      #   ary.each do |v|
      #     v
      #   end
      #
      class RedundantWithObject < Base
        include RangeHelp
        extend AutoCorrector

        MSG_EACH_WITH_OBJECT = 'Use `each` instead of `each_with_object`.'
        MSG_WITH_OBJECT = 'Remove redundant `with_object`.'

        def on_block(node)
          return unless (send = redundant_with_object?(node))

          range = with_object_range(send)

          add_offense(range, message: message(send)) do |corrector|
            if send.method?(:each_with_object)
              corrector.replace(range, 'each')
            else
              corrector.remove(range)
              corrector.remove(send.loc.dot)
            end
          end
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        # @!method redundant_with_object?(node)
        def_node_matcher :redundant_with_object?, <<~PATTERN
          {
            (block
              $(call _ {:each_with_object :with_object} _) (args (arg _)) ...)
            (numblock
              $(call _ {:each_with_object :with_object} _) 1 ...)
            (itblock
              $(call _ {:each_with_object :with_object} _) _ ...)
          }
        PATTERN

        def message(node)
          if node.method?(:each_with_object)
            MSG_EACH_WITH_OBJECT
          else
            MSG_WITH_OBJECT
          end
        end

        def with_object_range(send)
          range_between(send.loc.selector.begin_pos, send.source_range.end_pos)
        end
      end
    end
  end
end
