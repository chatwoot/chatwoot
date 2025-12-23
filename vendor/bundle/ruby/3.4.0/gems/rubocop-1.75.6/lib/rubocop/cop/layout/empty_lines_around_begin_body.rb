# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks if empty lines exist around the bodies of begin-end
      # blocks.
      #
      # @example
      #
      #   # bad
      #   begin
      #
      #     # ...
      #
      #   end
      #
      #   # good
      #   begin
      #     # ...
      #   end
      #
      class EmptyLinesAroundBeginBody < Base
        include EmptyLinesAroundBody
        extend AutoCorrector

        KIND = '`begin`'

        def on_kwbegin(node)
          check(node, nil)
        end

        private

        def style
          :no_empty_lines
        end
      end
    end
  end
end
