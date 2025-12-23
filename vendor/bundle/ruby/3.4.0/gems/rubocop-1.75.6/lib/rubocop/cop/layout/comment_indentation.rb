# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks the indentation of comments.
      #
      # @example
      #   # bad
      #     # comment here
      #   def method_name
      #   end
      #
      #     # comment here
      #   a = 'hello'
      #
      #   # yet another comment
      #     if true
      #       true
      #     end
      #
      #   # good
      #   # comment here
      #   def method_name
      #   end
      #
      #   # comment here
      #   a = 'hello'
      #
      #   # yet another comment
      #   if true
      #     true
      #   end
      #
      # @example AllowForAlignment: false (default)
      #   # bad
      #   a = 1 # A really long comment
      #         # spanning two lines.
      #
      #   # good
      #   # A really long comment spanning one line.
      #   a = 1
      #
      # @example AllowForAlignment: true
      #   # good
      #   a = 1 # A really long comment
      #         # spanning two lines.
      class CommentIndentation < Base
        include Alignment
        extend AutoCorrector

        MSG = 'Incorrect indentation detected (column %<column>d ' \
              'instead of %<correct_comment_indentation>d).'

        def on_new_investigation
          processed_source.comments.each_with_index { |comment, ix| check(comment, ix) }
        end

        private

        def autocorrect(corrector, comment)
          autocorrect_preceding_comments(corrector, comment)

          autocorrect_one(corrector, comment)
        end

        # Corrects all comment lines that occur immediately before the given
        # comment and have the same indentation. This is to avoid a long chain
        # of correcting, saving the file, parsing and inspecting again, and
        # then correcting one more line, and so on.
        def autocorrect_preceding_comments(corrector, comment)
          comments = processed_source.comments
          index = comments.index(comment)

          comments[0..index]
            .reverse_each
            .each_cons(2)
            .take_while { |below, above| should_correct?(above, below) }
            .map { |_, above| autocorrect_one(corrector, above) }
        end

        def should_correct?(preceding_comment, reference_comment)
          loc = preceding_comment.loc
          ref_loc = reference_comment.loc
          loc.line == ref_loc.line - 1 && loc.column == ref_loc.column
        end

        def autocorrect_one(corrector, comment)
          AlignmentCorrector.correct(corrector, processed_source, comment, @column_delta)
        end

        def check(comment, comment_index)
          return unless own_line_comment?(comment)

          next_line = line_after_comment(comment)
          correct_comment_indentation = correct_indentation(next_line)
          column = comment.loc.column

          @column_delta = correct_comment_indentation - column
          return if @column_delta.zero?

          if two_alternatives?(next_line)
            # Try the other
            correct_comment_indentation += configured_indentation_width
            # We keep @column_delta unchanged so that autocorrect changes to
            # the preferred style of aligning the comment with the keyword.
            return if column == correct_comment_indentation
          end

          return if correctly_aligned_with_preceding_comment?(comment_index, column)

          add_offense(comment, message: message(column, correct_comment_indentation)) do |corrector|
            autocorrect(corrector, comment)
          end
        end

        # Returns true if:
        # a) the cop is configured to allow extra indentation for alignment, and
        # b) the currently inspected comment is aligned with the nearest preceding end-of-line
        #    comment.
        def correctly_aligned_with_preceding_comment?(comment_index, column)
          return false unless cop_config['AllowForAlignment']

          processed_source.comments[0...comment_index].reverse_each do |other_comment|
            return other_comment.loc.column == column unless own_line_comment?(other_comment)
          end

          false
        end

        def message(column, correct_comment_indentation)
          format(MSG, column: column, correct_comment_indentation: correct_comment_indentation)
        end

        def own_line_comment?(comment)
          own_line = processed_source.lines[comment.loc.line - 1]
          /\A\s*#/.match?(own_line)
        end

        def line_after_comment(comment)
          lines = processed_source.lines
          lines[comment.loc.line..].find { |line| !line.blank? }
        end

        def correct_indentation(next_line)
          return 0 unless next_line

          indentation_of_next_line = next_line =~ /\S/
          indentation_of_next_line + if less_indented?(next_line)
                                       configured_indentation_width
                                     else
                                       0
                                     end
        end

        def less_indented?(line)
          rule = config.for_cop('Layout/AccessModifierIndentation')['EnforcedStyle'] == 'outdent'
          access_modifier = 'private|protected|public'
          /\A\s*(end\b|[)}\]])/.match?(line) || (rule && /\A\s*(#{access_modifier})\b/.match?(line))
        end

        def two_alternatives?(line)
          /^\s*(else|elsif|when|in|rescue|ensure)\b/.match?(line)
        end
      end
    end
  end
end
