# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of `+_.each_with_object({}) {...}+`,
      # `+_.map {...}.to_h+`, and `+Hash[_.map {...}]+` that are actually just
      # transforming the keys of a hash, and tries to use a simpler & faster
      # call to `transform_keys` instead.
      # It should only be enabled on Ruby version 2.5 or newer.
      # (`transform_keys` was added in Ruby 2.5.)
      #
      # @safety
      #   This cop is unsafe, as it can produce false positives if we are
      #   transforming an enumerable of key-value-like pairs that isn't actually
      #   a hash, e.g.: `[[k1, v1], [k2, v2], ...]`
      #
      # @example
      #   # bad
      #   {a: 1, b: 2}.each_with_object({}) { |(k, v), h| h[foo(k)] = v }
      #   Hash[{a: 1, b: 2}.collect { |k, v| [foo(k), v] }]
      #   {a: 1, b: 2}.map { |k, v| [k.to_s, v] }.to_h
      #   {a: 1, b: 2}.to_h { |k, v| [k.to_s, v] }
      #
      #   # good
      #   {a: 1, b: 2}.transform_keys { |k| foo(k) }
      #   {a: 1, b: 2}.transform_keys { |k| k.to_s }
      class HashTransformKeys < Base
        include HashTransformMethod
        extend AutoCorrector
        extend TargetRubyVersion

        minimum_target_ruby_version 2.5

        # @!method on_bad_each_with_object(node)
        def_node_matcher :on_bad_each_with_object, <<~PATTERN
          (block
            (call !#array_receiver? :each_with_object (hash))
            (args
              (mlhs
                (arg $_)
                (arg _val))
              (arg _memo))
            (call (lvar _memo) :[]= $!`_memo $(lvar _val)))
        PATTERN

        # @!method on_bad_hash_brackets_map(node)
        def_node_matcher :on_bad_hash_brackets_map, <<~PATTERN
          (send
            (const _ :Hash)
            :[]
            (block
              (call !#array_receiver? {:map :collect})
              (args
                (arg $_)
                (arg _val))
              (array $_ $(lvar _val))))
        PATTERN

        # @!method on_bad_map_to_h(node)
        def_node_matcher :on_bad_map_to_h, <<~PATTERN
          (call
            (block
              (call !#array_receiver? {:map :collect})
              (args
                (arg $_)
                (arg _val))
              (array $_ $(lvar _val)))
            :to_h)
        PATTERN

        # @!method on_bad_to_h(node)
        def_node_matcher :on_bad_to_h, <<~PATTERN
          (block
            (call !#array_receiver? :to_h)
            (args
              (arg $_)
              (arg _val))
            (array $_ $(lvar _val)))
        PATTERN

        private

        def extract_captures(match)
          key_argname, key_body_expr, val_body_expr = *match
          Captures.new(key_argname, key_body_expr, val_body_expr)
        end

        def new_method_name
          'transform_keys'
        end
      end
    end
  end
end
