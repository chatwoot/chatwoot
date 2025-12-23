# frozen_string_literal: true

module RuboCop
  module Cop
    module Security
      # Checks for implementations of the `hash` method which combine
      # values using custom logic instead of delegating to `Array#hash`.
      #
      # Manually combining hashes is error prone and hard to follow, especially
      # when there are many values. Poor implementations may also introduce
      # performance or security concerns if they are prone to collisions.
      # Delegating to `Array#hash` is clearer and safer, although it might be slower
      # depending on the use case.
      #
      # @safety
      #   This cop may be unsafe if the application logic depends on the hash
      #   value, however this is inadvisable anyway.
      #
      # @example
      #
      #   # bad
      #   def hash
      #     @foo ^ @bar
      #   end
      #
      #   # good
      #   def hash
      #     [@foo, @bar].hash
      #   end
      class CompoundHash < Base
        COMBINATOR_IN_HASH_MSG = 'Use `[...].hash` instead of combining hash values manually.'
        MONUPLE_HASH_MSG =
          'Delegate hash directly without wrapping in an array when only using a single value.'
        REDUNDANT_HASH_MSG = 'Calling .hash on elements of a hashed array is redundant.'
        RESTRICT_ON_SEND = %i[hash ^ + * |].freeze

        # @!method hash_method_definition?(node)
        def_node_matcher :hash_method_definition?, <<~PATTERN
          {#static_hash_method_definition? | #dynamic_hash_method_definition?}
        PATTERN

        # @!method dynamic_hash_method_definition?(node)
        def_node_matcher :dynamic_hash_method_definition?, <<~PATTERN
          (block
            (send _ {:define_method | :define_singleton_method}
              (sym :hash))
            (args)
            _)
        PATTERN

        # @!method static_hash_method_definition?(node)
        def_node_matcher :static_hash_method_definition?, <<~PATTERN
          ({def | defs _} :hash
            (args)
            _)
        PATTERN

        # @!method bad_hash_combinator?(node)
        def_node_matcher :bad_hash_combinator?, <<~PATTERN
          ({send | op-asgn} _ {:^ | :+ | :* | :|} _)
        PATTERN

        # @!method monuple_hash?(node)
        def_node_matcher :monuple_hash?, <<~PATTERN
          (send (array _) :hash)
        PATTERN

        # @!method redundant_hash?(node)
        def_node_matcher :redundant_hash?, <<~PATTERN
          (
            ^^(send array ... :hash)
            _ :hash
          )
        PATTERN

        def contained_in_hash_method?(node, &block)
          node.each_ancestor.any? do |ancestor|
            hash_method_definition?(ancestor, &block)
          end
        end

        def outer_bad_hash_combinator?(node)
          bad_hash_combinator?(node) do
            yield true if node.each_ancestor.none? { |ancestor| bad_hash_combinator?(ancestor) }
          end
        end

        def on_send(node)
          outer_bad_hash_combinator?(node) do
            contained_in_hash_method?(node) do
              add_offense(node, message: COMBINATOR_IN_HASH_MSG)
            end
          end

          monuple_hash?(node) do
            add_offense(node, message: MONUPLE_HASH_MSG)
          end

          redundant_hash?(node) do
            add_offense(node, message: REDUNDANT_HASH_MSG)
          end
        end
        alias on_csend on_send
        alias on_op_asgn on_send
      end
    end
  end
end
