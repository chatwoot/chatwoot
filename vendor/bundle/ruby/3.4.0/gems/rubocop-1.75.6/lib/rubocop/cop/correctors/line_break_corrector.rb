# frozen_string_literal: true

module RuboCop
  module Cop
    # This class handles autocorrection for code that needs to be moved
    # to new lines.
    class LineBreakCorrector
      extend Alignment
      extend TrailingBody
      extend Util

      class << self
        attr_reader :processed_source

        def correct_trailing_body(configured_width:, corrector:, node:,
                                  processed_source:)
          @processed_source = processed_source
          range = first_part_of(node.to_a.last)
          eol_comment = processed_source.comment_at_line(node.source_range.line)

          break_line_before(range: range, node: node, corrector: corrector,
                            configured_width: configured_width)
          move_comment(eol_comment: eol_comment, node: node, corrector: corrector)
          remove_semicolon(node, corrector)
        end

        def break_line_before(range:, node:, corrector:, configured_width:,
                              indent_steps: 1)
          corrector.insert_before(
            range,
            "\n#{' ' * (node.loc.keyword.column + (indent_steps * configured_width))}"
          )
        end

        def move_comment(eol_comment:, node:, corrector:)
          return unless eol_comment

          text = eol_comment.source
          corrector.insert_before(node, "#{text}\n#{' ' * node.loc.keyword.column}")
          corrector.remove(eol_comment)
        end

        private

        def remove_semicolon(node, corrector)
          return unless semicolon(node)

          corrector.remove(semicolon(node).pos)
        end

        def semicolon(node)
          @semicolon ||= {}.compare_by_identity
          @semicolon[node] ||= processed_source.sorted_tokens.select(&:semicolon?).find do |token|
            next if token.pos.end_pos <= node.source_range.begin_pos

            same_line?(token, node.body) && trailing_class_definition?(token, node.body)
          end
        end

        def trailing_class_definition?(token, body)
          token.column < body.loc.column
        end
      end
    end
  end
end
