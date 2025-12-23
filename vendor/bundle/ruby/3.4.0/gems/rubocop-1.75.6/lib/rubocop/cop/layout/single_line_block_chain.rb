# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if method calls are chained onto single line blocks. It considers that a
      # line break before the dot improves the readability of the code.
      #
      # @example
      #   # bad
      #   example.select { |item| item.cond? }.join('-')
      #
      #   # good
      #   example.select { |item| item.cond? }
      #          .join('-')
      #
      #   # good (not a concern for this cop)
      #   example.select do |item|
      #     item.cond?
      #   end.join('-')
      #
      class SingleLineBlockChain < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Put method call on a separate line if chained to a single line block.'

        def self.autocorrect_incompatible_with
          [Style::MapToHash]
        end

        def on_send(node)
          range = offending_range(node)
          add_offense(range) { |corrector| corrector.insert_before(range, "\n") } if range
        end
        alias on_csend on_send

        private

        def offending_range(node)
          receiver = node.receiver
          return unless receiver&.any_block_type?

          receiver_location = receiver.loc
          closing_block_delimiter_line_num = receiver_location.end.line
          return if receiver_location.begin.line < closing_block_delimiter_line_num

          node_location = node.loc
          dot_range = node_location.dot
          return unless dot_range
          return unless call_method_after_block?(node, dot_range, closing_block_delimiter_line_num)

          range_between(dot_range.begin_pos, selector_range(node).end_pos)
        end

        def call_method_after_block?(node, dot_range, closing_block_delimiter_line_num)
          return false if dot_range.line > closing_block_delimiter_line_num

          dot_range.column < selector_range(node).column
        end

        def selector_range(node)
          # l.(1) has no selector, so we use the opening parenthesis instead
          node.loc.selector || node.loc.begin
        end
      end
    end
  end
end
