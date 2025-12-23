# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of block comments (=begin...=end).
      #
      # @example
      #   # bad
      #   =begin
      #   Multiple lines
      #   of comments...
      #   =end
      #
      #   # good
      #   # Multiple lines
      #   # of comments...
      #
      class BlockComments < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Do not use block comments.'
        BEGIN_LENGTH = "=begin\n".length
        END_LENGTH = "\n=end".length

        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless comment.document?

            add_offense(comment) do |corrector|
              eq_begin, eq_end, contents = parts(comment)

              corrector.remove(eq_begin)
              unless contents.empty?
                corrector.replace(
                  contents,
                  contents.source.gsub(/\A/, '# ').gsub("\n\n", "\n#\n").gsub(/\n(?=[^#])/, "\n# ")
                )
              end
              corrector.remove(eq_end)
            end
          end
        end

        private

        def parts(comment)
          expr = comment.source_range
          eq_begin = expr.resize(BEGIN_LENGTH)
          eq_end = eq_end_part(comment, expr)
          contents = range_between(eq_begin.end_pos, eq_end.begin_pos)
          [eq_begin, eq_end, contents]
        end

        def eq_end_part(comment, expr)
          if comment.text.chomp == comment.text
            range_between(expr.end_pos - END_LENGTH - 1, expr.end_pos - 2)
          else
            range_between(expr.end_pos - END_LENGTH, expr.end_pos)
          end
        end
      end
    end
  end
end
