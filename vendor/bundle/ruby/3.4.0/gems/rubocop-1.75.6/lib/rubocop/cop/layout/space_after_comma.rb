# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for comma (`,`) not followed by some kind of space.
      #
      # @example
      #
      #   # bad
      #   [1,2]
      #   { foo:bar,}
      #
      #   # good
      #   [1, 2]
      #   { foo:bar, }
      class SpaceAfterComma < Base
        include SpaceAfterPunctuation
        extend AutoCorrector

        def space_style_before_rcurly
          cfg = config.for_cop('Layout/SpaceInsideHashLiteralBraces')
          cfg['EnforcedStyle'] || 'space'
        end

        def kind(token)
          'comma' if token.comma? && !before_semicolon?(token)
        end

        private

        def before_semicolon?(token)
          tokens = processed_source.tokens

          tokens[tokens.index(token) + 1].semicolon?
        end
      end
    end
  end
end
