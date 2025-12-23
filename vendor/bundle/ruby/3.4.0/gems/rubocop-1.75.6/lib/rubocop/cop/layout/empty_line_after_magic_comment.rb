# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for a newline after the final magic comment.
      #
      # @example
      #   # good
      #   # frozen_string_literal: true
      #
      #   # Some documentation for Person
      #   class Person
      #     # Some code
      #   end
      #
      #   # bad
      #   # frozen_string_literal: true
      #   # Some documentation for Person
      #   class Person
      #     # Some code
      #   end
      class EmptyLineAfterMagicComment < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Add an empty line after magic comments.'

        def on_new_investigation
          return unless (last_magic_comment = last_magic_comment(processed_source))
          return unless (next_line = processed_source[last_magic_comment.loc.line])
          return if next_line.strip.empty?

          offending_range = offending_range(last_magic_comment)

          add_offense(offending_range) do |corrector|
            corrector.insert_before(offending_range, "\n")
          end
        end

        private

        def offending_range(last_magic_comment)
          source_range(processed_source.buffer, last_magic_comment.loc.line + 1, 0)
        end

        # Find the last magic comment in the source file.
        #
        # Take all comments that precede the first line of code (or just take
        # them all in the case when there is no code), select the
        # magic comments, and return the last magic comment in the file.
        #
        # @return [Parser::Source::Comment] if magic comments exist before code
        # @return [nil] otherwise
        def last_magic_comment(source)
          comments_before_code(source)
            .reverse
            .find { |comment| MagicComment.parse(comment.text).any? }
        end

        def comments_before_code(source)
          if source.ast
            source.comments.take_while { |comment| comment.loc.line < source.ast.loc.line }
          else
            source.comments
          end
        end
      end
    end
  end
end
