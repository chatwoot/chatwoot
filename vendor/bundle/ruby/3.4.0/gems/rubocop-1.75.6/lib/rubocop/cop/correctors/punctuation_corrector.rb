# frozen_string_literal: true

module RuboCop
  module Cop
    # This autocorrects punctuation
    class PunctuationCorrector
      class << self
        def remove_space(corrector, space_before)
          corrector.remove(space_before)
        end

        def add_space(corrector, token)
          corrector.replace(token.pos, "#{token.pos.source} ")
        end

        def swap_comma(corrector, range)
          return unless range

          case range.source
          when ',' then corrector.remove(range)
          else          corrector.insert_after(range, ',')
          end
        end
      end
    end
  end
end
