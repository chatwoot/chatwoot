# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for top level return with arguments. If there is a
      # top-level return statement with an argument, then the argument is
      # always ignored. This is detected automatically since Ruby 2.7.
      #
      # @example
      #   # bad
      #   return 1
      #
      #   # good
      #   return
      class TopLevelReturnWithArgument < Base
        extend AutoCorrector

        MSG = 'Top level return with argument detected.'

        def on_return(return_node)
          return unless top_level_return_with_any_argument?(return_node)

          add_offense(return_node) do |corrector|
            remove_arguments(corrector, return_node)
          end
        end

        private

        def top_level_return_with_any_argument?(return_node)
          top_level_return?(return_node) && return_node.arguments?
        end

        def remove_arguments(corrector, return_node)
          corrector.replace(return_node, 'return')
        end

        # This cop works by validating the ancestors of the return node. A
        # top-level return node's ancestors should not be of block, def, or
        # defs type.
        def top_level_return?(return_node)
          return_node.each_ancestor(:block, :any_def).none?
        end
      end
    end
  end
end
