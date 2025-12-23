# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for the instantiation of array using redundant `Array` constructor.
      # Autocorrect replaces to array literal which is the simplest and fastest.
      #
      # @example
      #
      #   # bad
      #   Array.new([])
      #   Array[]
      #   Array([])
      #   Array.new(['foo', 'foo', 'foo'])
      #   Array['foo', 'foo', 'foo']
      #   Array(['foo', 'foo', 'foo'])
      #
      #   # good
      #   []
      #   ['foo', 'foo', 'foo']
      #   Array.new(3, 'foo')
      #   Array.new(3) { 'foo' }
      #
      class RedundantArrayConstructor < Base
        extend AutoCorrector

        MSG = 'Remove the redundant `Array` constructor.'

        RESTRICT_ON_SEND = %i[new [] Array].freeze

        # @!method redundant_array_constructor(node)
        def_node_matcher :redundant_array_constructor, <<~PATTERN
          {
            (send
              (const {nil? cbase} :Array) :new
              $(array ...))
            (send
              (const {nil? cbase} :Array) :[]
              $...)
            (send
              nil? :Array
              $(array ...))
          }
        PATTERN

        def on_send(node)
          return unless (array_literal = redundant_array_constructor(node))

          receiver = node.receiver
          selector = node.loc.selector

          if node.method?(:new)
            range = receiver.source_range.join(selector)
            replacement = array_literal
          elsif node.method?(:Array)
            range = selector
            replacement = array_literal
          else
            range = receiver
            replacement = selector.begin.join(node.source_range.end)
          end

          register_offense(range, node, replacement)
        end

        private

        def register_offense(range, node, replacement)
          add_offense(range) do |corrector|
            corrector.replace(node, replacement.source)
          end
        end
      end
    end
  end
end
