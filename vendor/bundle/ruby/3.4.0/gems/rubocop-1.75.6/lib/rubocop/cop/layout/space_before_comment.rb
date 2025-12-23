# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for missing space between a token and a comment on the
      # same line.
      #
      # @example
      #   # bad
      #   1 + 1# this operation does ...
      #
      #   # good
      #   1 + 1 # this operation does ...
      class SpaceBeforeComment < Base
        extend AutoCorrector

        MSG = 'Put a space before an end-of-line comment.'

        def on_new_investigation
          processed_source.sorted_tokens.each_cons(2) do |token1, token2|
            next unless token2.comment?
            next unless same_line?(token1, token2)
            next unless token1.pos.end == token2.pos.begin

            range = token2.pos

            add_offense(range) { |corrector| corrector.insert_before(range, ' ') }
          end
        end
      end
    end
  end
end
