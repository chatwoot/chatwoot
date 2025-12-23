# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      # Checks for literals with extremely many entries. This is indicative of
      # configuration or data that may be better extracted somewhere else, like
      # a database, fetched from an API, or read from a non-code file (CSV,
      # JSON, YAML, etc.).
      #
      # @example
      #   # bad
      #   # Huge Array literal
      #   [1, 2, '...', 999_999_999]
      #
      #   # bad
      #   # Huge Hash literal
      #   { 1 => 1, 2 => 2, '...' => '...', 999_999_999 => 999_999_999}
      #
      #   # bad
      #   # Huge Set "literal"
      #   Set[1, 2, '...', 999_999_999]
      #
      #   # good
      #   # Reasonably sized Array literal
      #   [1, 2, '...', 10]
      #
      #   # good
      #   # Reading huge Array from external data source
      #   # File.readlines('numbers.txt', chomp: true).map!(&:to_i)
      #
      #   # good
      #   # Reasonably sized Hash literal
      #   { 1 => 1, 2 => 2, '...' => '...', 10 => 10}
      #
      #   # good
      #   # Reading huge Hash from external data source
      #   CSV.foreach('numbers.csv', headers: true).each_with_object({}) do |row, hash|
      #     hash[row["key"].to_i] = row["value"].to_i
      #   end
      #
      #   # good
      #   # Reasonably sized Set "literal"
      #   Set[1, 2, '...', 10]
      #
      #   # good
      #   # Reading huge Set from external data source
      #   SomeFramework.config_for(:something)[:numbers].to_set
      #
      class CollectionLiteralLength < Base
        MSG = 'Avoid hard coding large quantities of data in code. ' \
              'Prefer reading the data from an external source.'
        RESTRICT_ON_SEND = [:[]].freeze

        # @!method set_const?(node)
        def_node_matcher :set_const?, <<~PATTERN
          (const {cbase nil?} :Set)
        PATTERN

        def on_array(node)
          add_offense(node) if node.children.length >= collection_threshold
        end
        alias on_hash on_array

        def on_index(node)
          return unless set_const?(node.receiver)

          add_offense(node) if node.arguments.length >= collection_threshold
        end

        def on_send(node)
          on_index(node) if node.method?(:[])
        end

        private

        def collection_threshold
          cop_config.fetch('LengthThreshold', Float::INFINITY)
        end
      end
    end
  end
end
