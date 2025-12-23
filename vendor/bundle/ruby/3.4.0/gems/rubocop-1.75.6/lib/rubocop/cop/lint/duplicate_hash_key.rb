# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Checks for duplicated keys in hash literals.
      # This cop considers both primitive types and constants for the hash keys.
      #
      # This cop mirrors a warning in Ruby 2.2.
      #
      # @example
      #
      #   # bad
      #   hash = { food: 'apple', food: 'orange' }
      #
      #   # good
      #   hash = { food: 'apple', other_food: 'orange' }
      class DuplicateHashKey < Base
        include Duplication

        MSG = 'Duplicated key in hash literal.'

        def on_hash(node)
          keys = node.keys.select { |key| key.recursive_basic_literal? || key.const_type? }

          return unless duplicates?(keys)

          consecutive_duplicates(keys).each { |key| add_offense(key) }
        end
      end
    end
  end
end
