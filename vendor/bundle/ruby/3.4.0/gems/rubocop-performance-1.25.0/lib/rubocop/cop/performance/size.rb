# frozen_string_literal: true

module RuboCop
  module Cop
    module Performance
      # Identifies usages of `count` on an `Array` and `Hash` and change them to `size`.
      #
      # @example
      #   # bad
      #   [1, 2, 3].count
      #   (1..3).to_a.count
      #   Array[*1..3].count
      #   Array(1..3).count
      #
      #   # bad
      #   {a: 1, b: 2, c: 3}.count
      #   [[:foo, :bar], [1, 2]].to_h.count
      #   Hash[*('a'..'z')].count
      #   Hash(key: :value).count
      #
      #   # good
      #   [1, 2, 3].size
      #   (1..3).to_a.size
      #   Array[*1..3].size
      #   Array(1..3).size
      #
      #   # good
      #   {a: 1, b: 2, c: 3}.size
      #   [[:foo, :bar], [1, 2]].to_h.size
      #   Hash[*('a'..'z')].size
      #   Hash(key: :value).size
      #
      #   # good
      #   [1, 2, 3].count { |e| e > 2 }
      # TODO: Add advanced detection of variables that could
      # have been assigned to an array or a hash.
      class Size < Base
        extend AutoCorrector

        MSG = 'Use `size` instead of `count`.'
        RESTRICT_ON_SEND = %i[count].freeze

        def_node_matcher :array?, <<~PATTERN
          {
            [!nil? array_type?]
            (call _ :to_a)
            (send (const nil? :Array) :[] _)
            (send nil? :Array _)
          }
        PATTERN

        def_node_matcher :hash?, <<~PATTERN
          {
            [!nil? hash_type?]
            (call _ :to_h)
            (send (const nil? :Hash) :[] _)
            (send nil? :Hash _)
          }
        PATTERN

        def_node_matcher :count?, <<~PATTERN
          (call {#array? #hash?} :count)
        PATTERN

        def on_send(node)
          return if node.parent&.block_type? || !count?(node)

          add_offense(node.loc.selector) do |corrector|
            corrector.replace(node.loc.selector, 'size')
          end
        end
        alias on_csend on_send
      end
    end
  end
end
