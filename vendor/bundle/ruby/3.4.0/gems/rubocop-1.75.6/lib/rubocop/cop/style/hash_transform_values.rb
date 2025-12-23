# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of `+_.each_with_object({}) {...}+`,
      # `+_.map {...}.to_h+`, and `+Hash[_.map {...}]+` that are actually just
      # transforming the values of a hash, and tries to use a simpler & faster
      # call to `transform_values` instead.
      #
      # @safety
      #   This cop is unsafe, as it can produce false positives if we are
      #   transforming an enumerable of key-value-like pairs that isn't actually
      #   a hash, e.g.: `[[k1, v1], [k2, v2], ...]`
      #
      # @example
      #   # bad
      #   {a: 1, b: 2}.each_with_object({}) { |(k, v), h| h[k] = foo(v) }
      #   Hash[{a: 1, b: 2}.collect { |k, v| [k, foo(v)] }]
      #   {a: 1, b: 2}.map { |k, v| [k, v * v] }.to_h
      #   {a: 1, b: 2}.to_h { |k, v| [k, v * v] }
      #
      #   # good
      #   {a: 1, b: 2}.transform_values { |v| foo(v) }
      #   {a: 1, b: 2}.transform_values { |v| v * v }
      class HashTransformValues < Base
        include HashTransformMethod
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.4

        # @!method on_bad_each_with_object(node)
        def_node_matcher :on_bad_each_with_object, <<~PATTERN
          (block
            (call !#array_receiver? :each_with_object (hash))
            (args
              (mlhs
                (arg _key)
                (arg $_))
              (arg _memo))
            (call (lvar _memo) :[]= $(lvar _key) $!`_memo))
        PATTERN

        # @!method on_bad_hash_brackets_map(node)
        def_node_matcher :on_bad_hash_brackets_map, <<~PATTERN
          (send
            (const _ :Hash)
            :[]
            (block
              (call !#array_receiver? {:map :collect})
              (args
                (arg _key)
                (arg $_))
              (array $(lvar _key) $_)))
        PATTERN

        # @!method on_bad_map_to_h(node)
        def_node_matcher :on_bad_map_to_h, <<~PATTERN
          (call
            (block
              (call !#array_receiver? {:map :collect})
              (args
                (arg _key)
                (arg $_))
              (array $(lvar _key) $_))
            :to_h)
        PATTERN

        # @!method on_bad_to_h(node)
        def_node_matcher :on_bad_to_h, <<~PATTERN
          (block
            (call !#array_receiver? :to_h)
            (args
              (arg _key)
              (arg $_))
            (array $(lvar _key) $_))
        PATTERN

        private

        def extract_captures(match)
          val_argname, key_body_expr, val_body_expr = *match
          Captures.new(val_argname, val_body_expr, key_body_expr)
        end

        def new_method_name
          'transform_values'
        end
      end
    end
  end
end
