# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Use `Hash#dig` instead of chaining potentially null `fetch` calls.
      #
      # When `fetch(identifier, nil)` calls are chained on a hash, the expectation
      # is that each step in the chain returns either `nil` or another hash,
      # and in both cases, these can be simplified with a single call to `dig` with
      # multiple arguments.
      #
      # If the 2nd parameter is `{}` or `Hash.new`, an offense will also be registered,
      # as long as the final call in the chain is a nil value. If a non-nil value is given,
      # the chain will not be registered as an offense, as the default value cannot be safely
      # given with `dig`.
      #
      # NOTE: See `Style/DigChain` for replacing chains of `dig` calls with
      # a single method call.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is a `Hash` or that `fetch` or `dig` have the expected standard implementation.
      #
      # @example
      #   # bad
      #   hash.fetch('foo', nil)&.fetch('bar', nil)
      #
      #   # bad
      #   # earlier members of the chain can return `{}` as long as the final `fetch`
      #   # has `nil` as a default value
      #   hash.fetch('foo', {}).fetch('bar', nil)
      #
      #   # good
      #   hash.dig('foo', 'bar')
      #
      #   # ok - not handled by the cop since the final `fetch` value is non-nil
      #   hash.fetch('foo', {}).fetch('bar', {})
      #
      class HashFetchChain < Base
        extend AutoCorrector
        extend TargetRubyVersion

        MSG = 'Use `%<replacement>s` instead.'
        RESTRICT_ON_SEND = %i[fetch].freeze

        minimum_target_ruby_version 2.3

        # @!method diggable?(node)
        def_node_matcher :diggable?, <<~PATTERN
          (call _ :fetch $_arg {nil (hash) (send (const {nil? cbase} :Hash) :new)})
        PATTERN

        def on_send(node)
          return if ignored_node?(node)
          return if last_fetch_non_nil?(node)

          last_replaceable_node, arguments = inspect_chain(node)
          return unless last_replaceable_node
          return unless arguments.size > 1

          range = last_replaceable_node.selector.join(node.loc.end)
          replacement = replacement(arguments)
          message = format(MSG, replacement: replacement)

          add_offense(range, message: message) do |corrector|
            corrector.replace(range, replacement)
          end
        end
        alias on_csend on_send

        private

        def last_fetch_non_nil?(node)
          # When chaining `fetch` methods, `fetch(x, {})` is acceptable within
          # the chain, as long as the last method in the chain has a `nil`
          # default value.

          return false unless node.method?(:fetch)

          !node.last_argument&.nil_type?
        end

        def inspect_chain(node)
          arguments = []

          while (arg = diggable?(node))
            arguments.unshift(arg)
            ignore_node(node)
            last_replaceable_node = node
            node = node.receiver
          end

          [last_replaceable_node, arguments]
        end

        def replacement(arguments)
          values = arguments.map(&:source).join(', ')
          "dig(#{values})"
        end
      end
    end
  end
end
