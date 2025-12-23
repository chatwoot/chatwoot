# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for semicolon (`;`) preceded by space.
      #
      # @example
      #   # bad
      #   x = 1 ; y = 2
      #
      #   # good
      #   x = 1; y = 2
      class SpaceBeforeSemicolon < Base
        include SpaceBeforePunctuation
        extend AutoCorrector

        def kind(token)
          'semicolon' if token.semicolon?
        end
      end
    end
  end
end
