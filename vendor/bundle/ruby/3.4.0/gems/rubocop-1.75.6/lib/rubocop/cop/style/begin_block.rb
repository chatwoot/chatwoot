# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for BEGIN blocks.
      #
      # @example
      #   # bad
      #   BEGIN { test }
      #
      class BeginBlock < Base
        MSG = 'Avoid the use of `BEGIN` blocks.'

        def on_preexe(node)
          add_offense(node.loc.keyword)
        end
      end
    end
  end
end
