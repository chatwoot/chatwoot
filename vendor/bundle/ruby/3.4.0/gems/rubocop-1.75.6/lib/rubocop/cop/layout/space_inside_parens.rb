# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for spaces inside ordinary round parentheses.
      #
      # @example EnforcedStyle: no_space (default)
      #   # The `no_space` style enforces that parentheses do not have spaces.
      #
      #   # bad
      #   f( 3)
      #   g = (a + 3 )
      #   f( )
      #
      #   # good
      #   f(3)
      #   g = (a + 3)
      #   f()
      #
      # @example EnforcedStyle: space
      #   # The `space` style enforces that parentheses have a space at the
      #   # beginning and end.
      #   # Note: Empty parentheses should not have spaces.
      #
      #   # bad
      #   f(3)
      #   g = (a + 3)
      #   y( )
      #
      #   # good
      #   f( 3 )
      #   g = ( a + 3 )
      #   y()
      #
      # @example EnforcedStyle: compact
      #   # The `compact` style enforces that parentheses have a space at the
      #   # beginning with the exception that successive parentheses are allowed.
      #   # Note: Empty parentheses should not have spaces.
      #
      #   # bad
      #   f(3)
      #   g = (a + 3)
      #   y( )
      #   g( f( x ) )
      #   g( f( x( 3 ) ), 5 )
      #   g( ( ( 3 + 5 ) * f) ** x, 5 )
      #
      #   # good
      #   f( 3 )
      #   g = ( a + 3 )
      #   y()
      #   g( f( x ))
      #   g( f( x( 3 )), 5 )
      #   g((( 3 + 5 ) * f ) ** x, 5 )
      #
      class SpaceInsideParens < Base
        include SurroundingSpace
        include RangeHelp
        include ConfigurableEnforcedStyle
        extend AutoCorrector

        MSG       = 'Space inside parentheses detected.'
        MSG_SPACE = 'No space inside parentheses detected.'

        def on_new_investigation
          tokens = processed_source.sorted_tokens

          case style
          when :space
            process_with_space_style(tokens)
          when :compact
            process_with_compact_style(tokens)
          else
            correct_extraneous_space(tokens)
          end
        end

        private

        def process_with_space_style(tokens)
          tokens.each_cons(2) do |token1, token2|
            correct_extraneous_space_in_empty_parens(token1, token2)
            correct_missing_space(token1, token2)
          end
        end

        def process_with_compact_style(tokens)
          tokens.each_cons(2) do |token1, token2|
            correct_extraneous_space_in_empty_parens(token1, token2)
            if !left_parens?(token1, token2) && !right_parens?(token1, token2)
              correct_missing_space(token1, token2)
            else
              correct_extraneous_space_between_consecutive_parens(token1, token2)
            end
          end
        end

        def correct_extraneous_space(tokens)
          tokens.each_cons(2) do |token1, token2|
            next unless parens?(token1, token2)

            # If the second token is a comment, that means that a line break
            # follows, and that the rules for space inside don't apply.
            next if token2.comment?
            next unless same_line?(token1, token2) && token1.space_after?

            range = range_between(token1.end_pos, token2.begin_pos)
            add_offense(range) do |corrector|
              corrector.remove(range)
            end
          end
        end

        def correct_extraneous_space_between_consecutive_parens(token1, token2)
          return if range_between(token1.end_pos, token2.begin_pos).source != ' '

          range = range_between(token1.end_pos, token2.begin_pos)
          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end

        def correct_extraneous_space_in_empty_parens(token1, token2)
          return unless token1.left_parens? && token2.right_parens?

          return if range_between(token1.begin_pos, token2.end_pos).source == '()'

          range = range_between(token1.end_pos, token2.begin_pos)
          add_offense(range) do |corrector|
            corrector.remove(range)
          end
        end

        def correct_missing_space(token1, token2)
          return if can_be_ignored?(token1, token2)

          range = if token1.left_parens?
                    range_between(token2.begin_pos, token2.begin_pos + 1)
                  elsif token2.right_parens?
                    range_between(token2.begin_pos, token2.end_pos)
                  end

          add_offense(range, message: MSG_SPACE) do |corrector|
            corrector.insert_before(range, ' ')
          end
        end

        def parens?(token1, token2)
          token1.left_parens? || token2.right_parens?
        end

        def left_parens?(token1, token2)
          token1.left_parens? && token2.left_parens?
        end

        def right_parens?(token1, token2)
          token1.right_parens? && token2.right_parens?
        end

        def can_be_ignored?(token1, token2)
          return true unless parens?(token1, token2)

          # Ignore empty parentheses.
          return true if range_between(token1.begin_pos, token2.end_pos).source == '()'

          # If the second token is a comment, that means that a line break
          # follows, and that the rules for space inside don't apply.
          return true if token2.comment?

          !same_line?(token1, token2) || token1.space_after?
        end
      end
    end
  end
end
