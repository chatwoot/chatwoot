# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Checks for `map { |id| [id] }` and suggests replacing it with `zip`.
      #
      # @safety
      #   This cop is unsafe for novel definitions of `map` and `collect`
      #   on non-Enumerable objects that do not respond to `zip`.
      #   To make your object enumerable, define an `each` method
      #   as described in https://ruby-doc.org/core/Enumerable.html
      #
      # @example
      #   # bad
      #   [1, 2, 3].map { |id| [id] }
      #
      #   # good
      #   [1, 2, 3].zip
      class ZipWithoutBlock < Base
        extend AutoCorrector

        MSG = 'Use `zip` without a block argument instead.'
        RESTRICT_ON_SEND = Set.new(%i[map collect]).freeze

        # @!method map_with_array?(node)
        def_node_matcher :map_with_array?, <<~PATTERN
          {
            (block (call !nil? RESTRICT_ON_SEND) (args (arg _)) (array (lvar _)))
            (numblock (call !nil? RESTRICT_ON_SEND) 1 (array (lvar _)))
            (itblock (call !nil? RESTRICT_ON_SEND) :it (array (lvar _)))
          }
        PATTERN

        def on_send(node)
          return unless map_with_array?(node.parent)

          register_offense(node)
        end
        alias on_csend on_send

        private

        def register_offense(node)
          offense_range = offense_range(node)
          add_offense(offense_range) do |corrector|
            corrector.replace(offense_range, 'zip')
          end
        end

        def offense_range(node)
          node.loc.selector.join(node.parent.loc.end)
        end
      end
    end
  end
end
