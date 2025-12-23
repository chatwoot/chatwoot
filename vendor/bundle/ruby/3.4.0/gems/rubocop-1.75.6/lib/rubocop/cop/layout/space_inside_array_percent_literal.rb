# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for unnecessary additional spaces inside array percent literals
      # (i.e. %i/%w).
      #
      # Note that blank percent literals (e.g. `%i( )`) are checked by
      # `Layout/SpaceInsidePercentLiteralDelimiters`.
      #
      # @example
      #
      #   # bad
      #   %w(foo  bar  baz)
      #   # good
      #   %i(foo bar baz)
      class SpaceInsideArrayPercentLiteral < Base
        include MatchRange
        include PercentLiteral
        extend AutoCorrector

        MSG = 'Use only a single space inside array percent literal.'
        MULTIPLE_SPACES_BETWEEN_ITEMS_REGEX = /(?:[\S&&[^\\]](?:\\ )*)( {2,})(?=\S)/.freeze

        def on_array(node)
          process(node, '%i', '%I', '%w', '%W')
        end

        def on_percent_literal(node)
          each_unnecessary_space_match(node) do |range|
            add_offense(range) do |corrector|
              corrector.replace(range, ' ')
            end
          end
        end

        private

        def each_unnecessary_space_match(node, &blk)
          each_match_range(contents_range(node), MULTIPLE_SPACES_BETWEEN_ITEMS_REGEX, &blk)
        end
      end
    end
  end
end
