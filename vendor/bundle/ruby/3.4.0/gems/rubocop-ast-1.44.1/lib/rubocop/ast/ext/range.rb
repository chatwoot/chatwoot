# frozen_string_literal: true

module RuboCop
  module AST
    module Ext
      # Extensions to Parser::AST::Range
      module Range
        # @return [Range] the range of line numbers for the node
        # If `exclude_end` is `true`, then the range will be exclusive.
        #
        # Assume that `node` corresponds to the following array literal:
        #
        #   [
        #     :foo,
        #     :bar
        #   ]
        #
        #   node.loc.begin.line_span                       # => 1..1
        #   node.source_range.line_span(exclude_end: true) # => 1...4
        def line_span(exclude_end: false)
          ::Range.new(first_line, last_line, exclude_end)
        end
      end
    end
  end
end

Parser::Source::Range.include RuboCop::AST::Ext::Range
