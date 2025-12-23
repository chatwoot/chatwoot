# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `array.compact.flatten.map { |x| x.downcase }`.
      # Each of these methods (`compact`, `flatten`, `map`) will generate a new intermediate array
      # that is promptly thrown away. Instead it is faster to mutate when we know it's safe.
      #
      # @example
      #   # bad
      #   array = ["a", "b", "c"]
      #   array.compact.flatten.map { |x| x.downcase }
      #
      #   # good
      #   array = ["a", "b", "c"]
      #   array.compact!
      #   array.flatten!
      #   array.map! { |x| x.downcase }
      #   array
      class ChainArrayAllocation < Base
        # These methods return a new array but only sometimes. They must be
        # called with an argument. For example:
        #
        #   [1,2].first    # => 1
        #   [1,2].first(1) # => [1]
        #
        RETURN_NEW_ARRAY_WHEN_ARGS = %i[first last pop sample shift].to_set.freeze

        # These methods return a new array only when called without a block.
        RETURNS_NEW_ARRAY_WHEN_NO_BLOCK = %i[zip product].to_set.freeze

        # These methods ALWAYS return a new array
        # after they're called it's safe to mutate the resulting array
        ALWAYS_RETURNS_NEW_ARRAY = %i[* + - collect compact drop
                                      drop_while flatten map reject
                                      reverse rotate select shuffle sort
                                      take take_while transpose uniq
                                      values_at |].to_set.freeze

        # These methods have a mutation alternative. For example :collect
        # can be called as :collect!
        HAS_MUTATION_ALTERNATIVE = %i[collect compact flatten map reject
                                      reverse rotate select shuffle sort uniq].to_set.freeze

        RETURNS_NEW_ARRAY = (ALWAYS_RETURNS_NEW_ARRAY + RETURNS_NEW_ARRAY_WHEN_NO_BLOCK).freeze

        RESTRICT_ON_SEND = RETURNS_NEW_ARRAY

        MSG = 'Use unchained `%<method>s` and `%<second_method>s!` ' \
              '(followed by `return array` if required) instead of chaining ' \
              '`%<method>s...%<second_method>s`.'

        def_node_matcher :chain_array_allocation?, <<~PATTERN
          (send {
            (send _ $%RETURN_NEW_ARRAY_WHEN_ARGS {int lvar ivar cvar gvar send})
            (any_block (send _ $%ALWAYS_RETURNS_NEW_ARRAY) ...)
            (send _ $%RETURNS_NEW_ARRAY ...)
          } $%HAS_MUTATION_ALTERNATIVE ...)
        PATTERN

        def on_send(node)
          chain_array_allocation?(node) do |fm, sm|
            return if node.each_descendant(:send).any? { |descendant| descendant.method?(:lazy) }
            return if node.method?(:select) && !enumerable_select_method?(node.receiver)

            range = node.loc.selector.begin.join(node.source_range.end)

            add_offense(range, message: format(MSG, method: fm, second_method: sm))
          end
        end

        private

        def enumerable_select_method?(node)
          # NOTE: `QueryMethods#select` in Rails accepts positional arguments, whereas `Enumerable#select` does not.
          #        This difference can be utilized to reduce the knowledge requirements related to `select`.
          node.any_block_type? && node.send_node.arguments.empty?
        end
      end
    end
  end
end
