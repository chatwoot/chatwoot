# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for `:true` and `:false` symbols.
      # In most cases it would be a typo.
      #
      # @safety
      #   Autocorrection is unsafe for this cop because code relying
      #   on `:true` or `:false` symbols will break when those are
      #   changed to actual booleans.
      #
      # @example
      #
      #   # bad
      #   :true
      #
      #   # good
      #   true
      #
      #   # bad
      #   :false
      #
      #   # good
      #   false
      class BooleanSymbol < Base
        extend AutoCorrector

        MSG = 'Symbol with a boolean name - you probably meant to use `%<boolean>s`.'

        # @!method boolean_symbol?(node)
        def_node_matcher :boolean_symbol?, '(sym {:true :false})'

        def on_sym(node)
          return unless boolean_symbol?(node)

          parent = node.parent
          return if parent&.array_type? && parent.percent_literal?(:symbol)

          add_offense(node, message: format(MSG, boolean: node.value)) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        def autocorrect(corrector, node)
          boolean_literal = node.source.delete(':')
          parent = node.parent
          if parent&.pair_type? && parent.colon? && node.equal?(parent.children[0])
            corrector.remove(parent.loc.operator)
            boolean_literal = "#{node.source} =>"
          end

          corrector.replace(node, boolean_literal)
        end
      end
    end
  end
end
