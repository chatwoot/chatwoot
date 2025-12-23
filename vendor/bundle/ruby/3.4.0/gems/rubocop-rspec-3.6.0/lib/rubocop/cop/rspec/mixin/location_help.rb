# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Helper methods to location.
      module LocationHelp
        module_function

        # @param node [RuboCop::AST::SendNode]
        # @return [Parser::Source::Range]
        # @example
        #   foo 1, 2
        #      ^^^^^
        def arguments_with_whitespace(node)
          node.loc.selector.end.with(
            end_pos: node.source_range.end_pos
          )
        end

        # @param node [RuboCop::AST::SendNode]
        # @return [Parser::Source::Range]
        # @example
        #   foo { bar }
        #      ^^^^^^^^
        def block_with_whitespace(node)
          return unless (parent = node.parent)
          return unless parent.block_type?

          node.source_range.end.with(
            end_pos: parent.source_range.end_pos
          )
        end
      end
    end
  end
end
