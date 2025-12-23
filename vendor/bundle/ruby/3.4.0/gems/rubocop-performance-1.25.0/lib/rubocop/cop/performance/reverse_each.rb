# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `reverse.each` and change them to use `reverse_each` instead.
      #
      # If the return value is used, it will not be detected because the result will be different.
      #
      # [source,ruby]
      # ----
      # [1, 2, 3].reverse.each {} #=> [3, 2, 1]
      # [1, 2, 3].reverse_each {} #=> [1, 2, 3]
      # ----
      #
      # @example
      #   # bad
      #   items.reverse.each
      #
      #   # good
      #   items.reverse_each
      class ReverseEach < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `reverse_each` instead of `reverse.each`.'
        RESTRICT_ON_SEND = %i[each].freeze

        def_node_matcher :reverse_each?, <<~MATCHER
          (call (call _ :reverse) :each)
        MATCHER

        def on_send(node)
          return if use_return_value?(node)

          reverse_each?(node) do
            range = offense_range(node)

            add_offense(range) do |corrector|
              corrector.replace(range, 'reverse_each')
            end
          end
        end
        alias on_csend on_send

        private

        def use_return_value?(node)
          !!node.ancestors.detect do |ancestor|
            ancestor.assignment? || ancestor.send_type? || ancestor.return_type?
          end
        end

        def offense_range(node)
          range_between(node.children.first.loc.selector.begin_pos, node.loc.selector.end_pos)
        end
      end
    end
  end
end
