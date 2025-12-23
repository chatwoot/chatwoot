# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for uses of the character literal ?x.
      # Starting with Ruby 1.9 character literals are
      # essentially one-character strings, so this syntax
      # is mostly redundant at this point.
      #
      # ? character literal can be used to express meta and control character.
      # That's a good use case of ? literal so it doesn't count it as an offense.
      #
      # @example
      #   # bad
      #   ?x
      #
      #   # good
      #   'x'
      #
      #   # good - control & meta escapes
      #   ?\C-\M-d
      #   "\C-\M-d" # same as above
      class CharacterLiteral < Base
        include StringHelp
        extend AutoCorrector

        MSG = 'Do not use the character literal - use string literal instead.'

        def offense?(node)
          # we don't register an offense for things like ?\C-\M-d
          node.character_literal? && node.source.size.between?(2, 3)
        end

        def autocorrect(corrector, node)
          string = node.source[1..]

          # special character like \n
          # or ' which needs to use "" or be escaped.
          if string.length == 2 || string == "'"
            corrector.replace(node, %("#{string}"))
          elsif string.length == 1 # normal character
            corrector.replace(node, "'#{string}'")
          end
        end

        # Dummy implementation of method in ConfigurableEnforcedStyle that is
        # called from StringHelp.
        def opposite_style_detected; end

        # Dummy implementation of method in ConfigurableEnforcedStyle that is
        # called from StringHelp.
        def correct_style_detected; end
      end
    end
  end
end
