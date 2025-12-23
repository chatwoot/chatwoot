# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for handling parentheses.
    module Parentheses
      private

      def parens_required?(node)
        range  = node.source_range
        source = range.source_buffer.source
        /[a-z]/.match?(source[range.begin_pos - 1]) || /[a-z]/.match?(source[range.end_pos])
      end
    end
  end
end
