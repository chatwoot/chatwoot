# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that braces used for hash literals have or don't have
      # surrounding space depending on configuration.
      #
      # Hash pattern matching is handled in the same way.
      #
      # @example EnforcedStyle: space (default)
      #   # The `space` style enforces that hash literals have
      #   # surrounding space.
      #
      #   # bad
      #   h = {a: 1, b: 2}
      #   foo = {{ a: 1 } => { b: { c: 2 }}}
      #
      #   # good
      #   h = { a: 1, b: 2 }
      #   foo = { { a: 1 } => { b: { c: 2 } } }
      #
      # @example EnforcedStyle: no_space
      #   # The `no_space` style enforces that hash literals have
      #   # no surrounding space.
      #
      #   # bad
      #   h = { a: 1, b: 2 }
      #   foo = {{ a: 1 } => { b: { c: 2 }}}
      #
      #   # good
      #   h = {a: 1, b: 2}
      #   foo = {{a: 1} => {b: {c: 2}}}
      #
      # @example EnforcedStyle: compact
      #   # The `compact` style normally requires a space inside
      #   # hash braces, with the exception that successive left
      #   # braces or right braces are collapsed together in nested hashes.
      #
      #   # bad
      #   h = { a: { b: 2 } }
      #   foo = { { a: 1 } => { b: { c: 2 } } }
      #
      #   # good
      #   h = { a: { b: 2 }}
      #   foo = {{ a: 1 } => { b: { c: 2 }}}
      #
      # @example EnforcedStyleForEmptyBraces: no_space (default)
      #   # The `no_space` EnforcedStyleForEmptyBraces style enforces that
      #   # empty hash braces do not contain spaces.
      #
      #   # bad
      #   foo = { }
      #   bar = {    }
      #   baz = {
      #   }
      #
      #   # good
      #   foo = {}
      #   bar = {}
      #   baz = {}
      #
      # @example EnforcedStyleForEmptyBraces: space
      #   # The `space` EnforcedStyleForEmptyBraces style enforces that
      #   # empty hash braces contain space.
      #
      #   # bad
      #   foo = {}
      #
      #   # good
      #   foo = { }
      #   foo = {    }
      #   foo = {
      #   }
      #
      class SpaceInsideHashLiteralBraces < Base
        include SurroundingSpace
        include ConfigurableEnforcedStyle
        include RangeHelp
        extend AutoCorrector

        MSG = 'Space inside %<problem>s.'

        def on_hash(node)
          tokens = processed_source.tokens_within(node)
          return unless tokens.first.left_brace? && tokens.last.right_curly_brace?

          check(tokens[0], tokens[1])
          check(tokens[-2], tokens[-1]) if tokens.size > 2
          check_whitespace_only_hash(node) if enforce_no_space_style_for_empty_braces?
        end
        alias on_hash_pattern on_hash

        private

        def check(token1, token2)
          # No offense if line break inside.
          return if token1.line < token2.line
          return if token2.comment? # Also indicates there's a line break.

          is_empty_braces = token1.left_brace? && token2.right_curly_brace?
          expect_space    = expect_space?(token1, token2)

          if offense?(token1, expect_space)
            incorrect_style_detected(token1, token2, expect_space, is_empty_braces)
          else
            correct_style_detected
          end
        end

        def expect_space?(token1, token2)
          is_same_braces  = token1.type == token2.type
          is_empty_braces = token1.left_brace? && token2.right_curly_brace?

          if is_same_braces && style == :compact
            false
          elsif is_empty_braces
            !enforce_no_space_style_for_empty_braces?
          else
            style != :no_space
          end
        end

        def incorrect_style_detected(token1, token2,
                                     expect_space, is_empty_braces)
          brace = (token1.left_brace? ? token1 : token2).pos
          range = expect_space ? brace : space_range(brace)
          detected_style = expect_space ? 'no_space' : 'space'

          add_offense(range, message: message(brace, is_empty_braces, expect_space)) do |corrector|
            autocorrect(corrector, range)
            ambiguous_or_unexpected_style_detected(detected_style, token1.text == token2.text)
          end
        end

        def autocorrect(corrector, range)
          case range.source
          when /\s/ then corrector.remove(range)
          when '{' then corrector.insert_after(range, ' ')
          else corrector.insert_before(range, ' ')
          end
        end

        def ambiguous_or_unexpected_style_detected(style, is_match)
          if is_match
            ambiguous_style_detected(style, :compact)
          else
            unexpected_style_detected(style)
          end
        end

        def offense?(token1, expect_space)
          has_space = token1.space_after?
          expect_space ? !has_space : has_space
        end

        def message(brace, is_empty_braces, expect_space)
          inside_what = if is_empty_braces
                          'empty hash literal braces'
                        else
                          brace.source
                        end
          problem = expect_space ? 'missing' : 'detected'
          format(MSG, problem: "#{inside_what} #{problem}")
        end

        def space_range(token_range)
          if token_range.source == '{'
            range_of_space_to_the_right(token_range)
          else
            range_of_space_to_the_left(token_range)
          end
        end

        def range_of_space_to_the_right(range)
          src = range.source_buffer.source
          end_pos = range.end_pos
          end_pos += 1 while /[ \t]/.match?(src[end_pos])

          range_between(range.begin_pos + 1, end_pos)
        end

        def range_of_space_to_the_left(range)
          src = range.source_buffer.source
          begin_pos = range.begin_pos
          begin_pos -= 1 while /[ \t]/.match?(src[begin_pos - 1])

          range_between(begin_pos, range.end_pos - 1)
        end

        def check_whitespace_only_hash(node)
          range = range_inside_hash(node)
          return unless range.source.match?(/\A\s+\z/m)

          add_offense(
            range,
            message: format(MSG, problem: 'empty hash literal braces detected')
          ) do |corrector|
            corrector.remove(range)
          end
        end

        def range_inside_hash(node)
          return node.source_range if node.location.begin.nil?

          range_between(node.location.begin.end_pos, node.location.end.begin_pos)
        end

        def enforce_no_space_style_for_empty_braces?
          cop_config['EnforcedStyleForEmptyBraces'] == 'no_space'
        end
      end
    end
  end
end
