# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Prefer using `Hash#compare_by_identity` rather than using `object_id`
      # for hash keys.
      #
      # This cop looks for hashes being keyed by objects' `object_id`, using
      # one of these methods: `key?`, `has_key?`, `fetch`, `[]` and `[]=`.
      #
      # @safety
      #   This cop is unsafe. Although unlikely, the hash could store both object
      #   ids and other values that need be compared by value, and thus
      #   could be a false positive.
      #
      #   Furthermore, this cop cannot guarantee that the receiver of one of the
      #   methods (`key?`, etc.) is actually a hash.
      #
      # @example
      #   # bad
      #   hash = {}
      #   hash[foo.object_id] = :bar
      #   hash.key?(baz.object_id)
      #
      #   # good
      #   hash = {}.compare_by_identity
      #   hash[foo] = :bar
      #   hash.key?(baz)
      #
      class HashCompareByIdentity < Base
        RESTRICT_ON_SEND = %i[key? has_key? fetch [] []=].freeze

        MSG = 'Use `Hash#compare_by_identity` instead of using `object_id` for keys.'

        # @!method id_as_hash_key?(node)
        def_node_matcher :id_as_hash_key?, <<~PATTERN
          (call _ {:key? :has_key? :fetch :[] :[]=} (send _ :object_id) ...)
        PATTERN

        def on_send(node)
          add_offense(node) if id_as_hash_key?(node)
        end
        alias on_csend on_send
      end
    end
  end
end
