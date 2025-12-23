# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking and correcting surrounding whitespace.
    module SurroundingSpace
      include RangeHelp

      NO_SPACE_COMMAND = 'Do not use'
      SPACE_COMMAND = 'Use'

      SINGLE_SPACE_REGEXP = /[ \t]/.freeze

      private

      def side_space_range(range:, side:, include_newlines: false)
        buffer = processed_source.buffer
        src = buffer.source

        begin_pos = range.begin_pos
        end_pos = range.end_pos
        if side == :left
          end_pos = begin_pos
          begin_pos = reposition(src, begin_pos, -1, include_newlines: include_newlines)
        end
        if side == :right
          begin_pos = end_pos
          end_pos = reposition(src, end_pos, 1, include_newlines: include_newlines)
        end
        Parser::Source::Range.new(buffer, begin_pos, end_pos)
      end

      def on_new_investigation
        @token_table = nil
        super
      end

      def no_space_offenses(node, # rubocop:disable Metrics/ParameterLists
                            left_token,
                            right_token,
                            message,
                            start_ok: false,
                            end_ok: false)
        if extra_space?(left_token, :left) && !start_ok
          space_offense(node, left_token, :right, message, NO_SPACE_COMMAND)
        end
        return if (!extra_space?(right_token, :right) || end_ok) ||
                  (autocorrect_with_disable_uncorrectable? && !start_ok)

        space_offense(node, right_token, :left, message, NO_SPACE_COMMAND)
      end

      def space_offenses(node, # rubocop:disable Metrics/ParameterLists
                         left_token,
                         right_token,
                         message,
                         start_ok: false,
                         end_ok: false)
        unless extra_space?(left_token, :left) || start_ok
          space_offense(node, left_token, :none, message, SPACE_COMMAND)
        end
        return if (extra_space?(right_token, :right) || end_ok) ||
                  (autocorrect_with_disable_uncorrectable? && !start_ok)

        space_offense(node, right_token, :none, message, SPACE_COMMAND)
      end

      def extra_space?(token, side)
        return false unless token

        if side == :left
          SINGLE_SPACE_REGEXP.match?(String(token.space_after?))
        else
          SINGLE_SPACE_REGEXP.match?(String(token.space_before?))
        end
      end

      def reposition(src, pos, step, include_newlines: false)
        offset = step == -1 ? -1 : 0
        pos += step while SINGLE_SPACE_REGEXP.match?(src[pos + offset]) ||
                          (include_newlines && src[pos + offset] == "\n")
        pos.negative? ? 0 : pos
      end

      def space_offense(node, token, side, message, command)
        range = side_space_range(range: token.pos, side: side)
        add_offense(range, message: format(message, command: command)) do |corrector|
          autocorrect(corrector, node) unless ignored_node?(node)

          ignore_node(node)
        end
      end

      def empty_offenses(node, left, right, message)
        range = range_between(left.begin_pos, right.end_pos)
        if offending_empty_space?(empty_config, left, right)
          empty_offense(node, range, message, 'Use one')
        end
        return unless offending_empty_no_space?(empty_config, left, right)

        empty_offense(node, range, message, 'Do not use')
      end

      def empty_offense(node, range, message, command)
        add_offense(range, message: format(message, command: command)) do |corrector|
          autocorrect(corrector, node)
        end
      end

      def empty_brackets?(left_bracket_token, right_bracket_token, tokens: processed_source.tokens)
        left_index = tokens.index(left_bracket_token)
        right_index = tokens.index(right_bracket_token)
        right_index && left_index == right_index - 1
      end

      def offending_empty_space?(config, left_token, right_token)
        config == 'space' && !space_between?(left_token, right_token)
      end

      def offending_empty_no_space?(config, left_token, right_token)
        config == 'no_space' && !no_character_between?(left_token, right_token)
      end

      def space_between?(left_bracket_token, right_bracket_token)
        left_bracket_token.end_pos + 1 == right_bracket_token.begin_pos &&
          processed_source.buffer.source[left_bracket_token.end_pos] == ' '
      end

      def no_character_between?(left_bracket_token, right_bracket_token)
        left_bracket_token.end_pos == right_bracket_token.begin_pos
      end
    end
  end
end
