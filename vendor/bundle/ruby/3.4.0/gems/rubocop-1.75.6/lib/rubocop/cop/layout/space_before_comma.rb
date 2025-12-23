# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks for comma (`,`) preceded by space.
      #
      # @example
      #   # bad
      #   [1 , 2 , 3]
      #   a(1 , 2)
      #   each { |a , b| }
      #
      #   # good
      #   [1, 2, 3]
      #   a(1, 2)
      #   each { |a, b| }
      #
      class SpaceBeforeComma < Base
        include SpaceBeforePunctuation
        extend AutoCorrector

        def kind(token)
          'comma' if token.comma?
        end
      end
    end
  end
end
