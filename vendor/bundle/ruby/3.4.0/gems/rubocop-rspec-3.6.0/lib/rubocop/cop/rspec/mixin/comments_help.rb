# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Help methods for working with nodes containing comments.
      module CommentsHelp
        include FinalEndLocation

        def source_range_with_comment(node)
          begin_pos = begin_pos_with_comment(node).begin_pos
          end_pos = end_line_position(node).end_pos

          Parser::Source::Range.new(buffer, begin_pos, end_pos)
        end

        def begin_pos_with_comment(node)
          first_comment = processed_source.ast_with_comments[node].first

          start_line_position(first_comment || node)
        end

        def start_line_position(node)
          buffer.line_range(node.loc.line)
        end

        def end_line_position(node)
          end_line = buffer.line_for_position(final_end_location(node).end_pos)
          buffer.line_range(end_line)
        end

        def buffer
          processed_source.buffer
        end
      end
    end
  end
end
