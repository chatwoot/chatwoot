# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for the deprecated use of keyword arguments as a default in `Hash.new`.
      #
      # This usage raises a warning in Ruby 3.3 and results in an error in Ruby 3.4.
      # In Ruby 3.4, keyword arguments will instead be used to change the behavior of a hash.
      # For example, the capacity option can be passed to create a hash with a certain size
      # if you know it in advance, for better performance.
      #
      # NOTE: The following corner case may result in a false negative when upgrading from Ruby 3.3
      # or earlier, but it is intentionally not detected to respect the expected usage in Ruby 3.4.
      #
      # [source,ruby]
      # ----
      # Hash.new(capacity: 42)
      # ----
      #
      # @example
      #
      #   # bad
      #   Hash.new(key: :value)
      #
      #   # good
      #   Hash.new({key: :value})
      #
      class HashNewWithKeywordArgumentsAsDefault < Base
        extend AutoCorrector

        MSG = 'Use a hash literal instead of keyword arguments.'
        RESTRICT_ON_SEND = %i[new].freeze

        # @!method hash_new(node)
        def_node_matcher :hash_new, <<~PATTERN
          (send (const {nil? (cbase)} :Hash) :new $[hash !braces?])
        PATTERN

        def on_send(node)
          return unless (first_argument = hash_new(node))

          if first_argument.pairs.one?
            key = first_argument.pairs.first.key
            return if key.respond_to?(:value) && key.value == :capacity
          end

          add_offense(first_argument) do |corrector|
            corrector.wrap(first_argument, '{', '}')
          end
        end
      end
    end
  end
end
