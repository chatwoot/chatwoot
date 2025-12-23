# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks empty comment.
      #
      # @example
      #   # bad
      #
      #   #
      #   class Foo
      #   end
      #
      #   # good
      #
      #   #
      #   # Description of `Foo` class.
      #   #
      #   class Foo
      #   end
      #
      # @example AllowBorderComment: true (default)
      #   # good
      #
      #   def foo
      #   end
      #
      #   #################
      #
      #   def bar
      #   end
      #
      # @example AllowBorderComment: false
      #   # bad
      #
      #   def foo
      #   end
      #
      #   #################
      #
      #   def bar
      #   end
      #
      # @example AllowMarginComment: true (default)
      #   # good
      #
      #   #
      #   # Description of `Foo` class.
      #   #
      #   class Foo
      #   end
      #
      # @example AllowMarginComment: false
      #   # bad
      #
      #   #
      #   # Description of `Foo` class.
      #   #
      #   class Foo
      #   end
      #
      class EmptyComment < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Source code comment is empty.'

        def on_new_investigation
          if allow_margin_comment?
            comments = concat_consecutive_comments(processed_source.comments)

            investigate(comments)
          else
            processed_source.comments.each do |comment|
              next unless empty_comment_only?(comment_text(comment))

              add_offense(comment) { |corrector| autocorrect(corrector, comment) }
            end
          end
        end

        private

        def investigate(comments)
          comments.each do |comment|
            next unless empty_comment_only?(comment[0])

            comment[1].each do |offense_comment|
              add_offense(offense_comment) do |corrector|
                autocorrect(corrector, offense_comment)
              end
            end
          end
        end

        def autocorrect(corrector, node)
          previous_token = previous_token(node)
          range = if previous_token && same_line?(node, previous_token)
                    range_with_surrounding_space(node.source_range, newlines: false)
                  else
                    range_by_whole_lines(node.source_range, include_final_newline: true)
                  end

          corrector.remove(range)
        end

        def concat_consecutive_comments(comments)
          consecutive_comments = comments.chunk_while do |i, j|
            i.loc.line.succ == j.loc.line && i.loc.column == j.loc.column
          end

          consecutive_comments.map do |chunk|
            joined_text = chunk.map { |c| comment_text(c) }.join
            [joined_text, chunk]
          end
        end

        def empty_comment_only?(comment_text)
          empty_comment_pattern = if allow_border_comment?
                                    /\A(#\n)+\z/
                                  else
                                    /\A(#+\n)+\z/
                                  end

          empty_comment_pattern.match?(comment_text)
        end

        def comment_text(comment)
          "#{comment.text.strip}\n"
        end

        def allow_border_comment?
          cop_config['AllowBorderComment']
        end

        def allow_margin_comment?
          cop_config['AllowMarginComment']
        end

        def current_token(comment)
          processed_source.tokens.find { |token| token.pos == comment.source_range }
        end

        def previous_token(node)
          current_token = current_token(node)
          index = processed_source.tokens.index(current_token)
          index.zero? ? nil : processed_source.tokens[index - 1]
        end
      end
    end
  end
end
