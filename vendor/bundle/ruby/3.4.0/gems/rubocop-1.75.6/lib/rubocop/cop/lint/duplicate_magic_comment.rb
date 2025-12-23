# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for duplicated magic comments.
      #
      # @example
      #
      #   # bad
      #
      #   # encoding: ascii
      #   # encoding: ascii
      #
      #   # good
      #
      #   # encoding: ascii
      #
      #   # bad
      #
      #   # frozen_string_literal: true
      #   # frozen_string_literal: true
      #
      #   # good
      #
      #   # frozen_string_literal: true
      #
      class DuplicateMagicComment < Base
        include FrozenStringLiteral
        include RangeHelp
        extend AutoCorrector

        MSG = 'Duplicate magic comment detected.'

        def on_new_investigation
          return if processed_source.buffer.source.empty?

          magic_comment_lines.each_value do |comment_lines|
            next if comment_lines.count <= 1

            comment_lines[1..].each do |comment_line|
              range = processed_source.buffer.line_range(comment_line + 1)

              register_offense(range)
            end
          end
        end

        private

        def magic_comment_lines
          comment_lines = { encoding_magic_comments: [], frozen_string_literal_magic_comments: [] }

          leading_magic_comments.each.with_index do |magic_comment, index|
            if magic_comment.encoding_specified?
              comment_lines[:encoding_magic_comments] << index
            elsif magic_comment.frozen_string_literal_specified?
              comment_lines[:frozen_string_literal_magic_comments] << index
            end
          end

          comment_lines
        end

        def register_offense(range)
          add_offense(range) do |corrector|
            corrector.remove(range_by_whole_lines(range, include_final_newline: true))
          end
        end
      end
    end
  end
end
