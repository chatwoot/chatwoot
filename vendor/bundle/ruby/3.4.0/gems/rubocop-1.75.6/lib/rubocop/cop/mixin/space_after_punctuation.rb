# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for cops checking for missing space after
    # punctuation.
    module SpaceAfterPunctuation
      MSG = 'Space missing after %<token>s.'

      def on_new_investigation
        each_missing_space(processed_source.tokens) do |token|
          add_offense(token.pos, message: format(MSG, token: kind(token))) do |corrector|
            PunctuationCorrector.add_space(corrector, token)
          end
        end
      end

      private

      def each_missing_space(tokens)
        tokens.each_cons(2) do |token1, token2|
          next unless kind(token1)
          next unless space_missing?(token1, token2)
          next unless space_required_before?(token2)

          yield token1
        end
      end

      def space_missing?(token1, token2)
        same_line?(token1, token2) && token2.column == token1.column + offset
      end

      def space_required_before?(token)
        !(allowed_type?(token) || (token.right_curly_brace? && space_forbidden_before_rcurly?))
      end

      def allowed_type?(token)
        %i[tRPAREN tRBRACK tPIPE tSTRING_DEND].include?(token.type)
      end

      def space_forbidden_before_rcurly?
        style = space_style_before_rcurly
        style == 'no_space'
      end

      # The normal offset, i.e., the distance from the punctuation
      # token where a space should be, is 1.
      def offset
        1
      end
    end
  end
end
