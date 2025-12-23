# frozen_string_literal: true

module RuboCop
  module Cop
    # This class does empty line autocorrection
    class EmptyLineCorrector
      class << self
        def correct(corrector, node)
          offense_style, range = node

          case offense_style
          when :no_empty_lines
            corrector.remove(range)
          when :empty_lines
            corrector.insert_before(range, "\n")
          end
        end

        def insert_before(corrector, node)
          corrector.insert_before(node, "\n")
        end
      end
    end
  end
end
