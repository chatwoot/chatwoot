# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for string literal concatenation at
      # the end of a line.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the
      #   receiver is a string, in which case replacing `<<` with `\`
      #   would result in a syntax error.
      #
      #   For example, this would be a false positive:
      #   [source,ruby]
      #   ----
      #   array << 'foo' <<
      #            'bar' <<
      #            'baz'
      #   ----
      #
      # @example
      #
      #   # bad
      #   some_str = 'ala' +
      #              'bala'
      #
      #   some_str = 'ala' <<
      #              'bala'
      #
      #   # good
      #   some_str = 'ala' \
      #              'bala'
      #
      class LineEndConcatenation < Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Use `\\` instead of `%<operator>s` to concatenate multiline strings.'
        CONCAT_TOKEN_TYPES = %i[tPLUS tLSHFT].freeze
        SIMPLE_STRING_TOKEN_TYPE = :tSTRING
        COMPLEX_STRING_BEGIN_TOKEN = :tSTRING_BEG
        COMPLEX_STRING_END_TOKEN = :tSTRING_END
        HIGH_PRECEDENCE_OP_TOKEN_TYPES = %i[tSTAR2 tPERCENT tDOT tLBRACK2].freeze
        QUOTE_DELIMITERS = %w[' "].freeze

        def self.autocorrect_incompatible_with
          [Style::RedundantInterpolation]
        end

        def on_new_investigation
          processed_source.tokens.each_index { |index| check_token_set(index) }
        end

        private

        def check_token_set(index)
          tokens = processed_source.tokens
          predecessor = tokens[index]
          operator = tokens[index + 1]
          successor = tokens[index + 2]

          return unless eligible_token_set?(predecessor, operator, successor)
          return if same_line?(operator, successor)

          next_successor = token_after_last_string(successor, index)
          return unless eligible_next_successor?(next_successor)

          register_offense(operator)
        end

        def register_offense(operator)
          message = format(MSG, operator: operator.text)

          add_offense(operator.pos, message: message) do |corrector|
            autocorrect(corrector, operator.pos)
          end
        end

        def autocorrect(corrector, operator_range)
          # Include any trailing whitespace so we don't create a syntax error.
          operator_range = range_with_surrounding_space(operator_range,
                                                        side: :right,
                                                        newlines: false)
          one_more_char = operator_range.resize(operator_range.size + 1)
          # Don't create a double backslash at the end of the line, in case
          # there already was a backslash after the concatenation operator.
          operator_range = one_more_char if one_more_char.source.end_with?('\\')

          corrector.replace(operator_range, '\\')
        end

        def eligible_token_set?(predecessor, operator, successor)
          eligible_successor?(successor) &&
            eligible_operator?(operator) &&
            eligible_predecessor?(predecessor)
        end

        def eligible_successor?(successor)
          successor && standard_string_literal?(successor)
        end

        def eligible_operator?(operator)
          CONCAT_TOKEN_TYPES.include?(operator.type)
        end

        def eligible_next_successor?(next_successor)
          !(next_successor && HIGH_PRECEDENCE_OP_TOKEN_TYPES.include?(next_successor.type))
        end

        def eligible_predecessor?(predecessor)
          standard_string_literal?(predecessor)
        end

        def token_after_last_string(successor, base_index)
          index = base_index + 3
          if successor.type == COMPLEX_STRING_BEGIN_TOKEN
            ends_to_find = 1
            while ends_to_find.positive?
              case processed_source.tokens[index].type
              when COMPLEX_STRING_BEGIN_TOKEN then ends_to_find += 1
              when COMPLEX_STRING_END_TOKEN then ends_to_find -= 1
              end
              index += 1
            end
          end
          processed_source.tokens[index]
        end

        def standard_string_literal?(token)
          case token.type
          when SIMPLE_STRING_TOKEN_TYPE
            true
          when COMPLEX_STRING_BEGIN_TOKEN, COMPLEX_STRING_END_TOKEN
            QUOTE_DELIMITERS.include?(token.text)
          else
            false
          end
        end
      end
    end
  end
end
