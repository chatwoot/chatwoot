# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for END blocks.
      #
      # @example
      #   # bad
      #   END { puts 'Goodbye!' }
      #
      #   # good
      #   at_exit { puts 'Goodbye!' }
      #
      class EndBlock < Base
        extend AutoCorrector

        MSG = 'Avoid the use of `END` blocks. Use `Kernel#at_exit` instead.'

        def on_postexe(node)
          add_offense(node.loc.keyword) do |corrector|
            corrector.replace(node.loc.keyword, 'at_exit')
          end
        end
      end
    end
  end
end
