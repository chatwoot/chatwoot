# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Do not set up test data using indexes (e.g., `item_1`, `item_2`).
      #
      # It makes reading the test harder because it's not clear what exactly
      # is tested by this particular example.
      #
      # The configurable options `AllowedIdentifiers` and `AllowedPatterns`
      # will also read those set in `Naming/VariableNumber`.
      #
      # @example `Max: 1 (default)`
      #   # bad
      #   let(:item_1) { create(:item) }
      #   let(:item_2) { create(:item) }
      #
      #   let(:item1) { create(:item) }
      #   let(:item2) { create(:item) }
      #
      #   # good
      #
      #   let(:visible_item) { create(:item, visible: true) }
      #   let(:invisible_item) { create(:item, visible: false) }
      #
      # @example `Max: 2`
      #   # bad
      #   let(:item_1) { create(:item) }
      #   let(:item_2) { create(:item) }
      #   let(:item_3) { create(:item) }
      #
      #   # good
      #   let(:item_1) { create(:item) }
      #   let(:item_2) { create(:item) }
      #
      # @example `AllowedIdentifiers: ['item_1', 'item_2']`
      #   # good
      #   let(:item_1) { create(:item) }
      #   let(:item_2) { create(:item) }
      #
      # @example `AllowedPatterns: ['item']`
      #   # good
      #   let(:item_1) { create(:item) }
      #   let(:item_2) { create(:item) }
      #
      class IndexedLet < Base
        include AllowedIdentifiers
        include AllowedPattern

        MSG = 'This `let` statement uses `%<index>s` in its name. ' \
              'Please give it a meaningful name.'

        # @!method let_name(node)
        def_node_matcher :let_name, <<~PATTERN
          {
            (block (send nil? #Helpers.all ({str sym} $_) ...) ...)
            (send nil? #Helpers.all ({str sym} $_) block_pass)
          }
        PATTERN

        def on_block(node) # rubocop:disable InternalAffairs/NumblockHandler
          return unless spec_group?(node)

          children = node.body&.child_nodes
          return unless children

          filter_indexed_lets(children).each do |let_node|
            index = let_name(let_node)[INDEX_REGEX]
            add_offense(let_node, message: format(MSG, index: index))
          end
        end

        private

        SUFFIX_INDEX_REGEX = /_?\d+$/.freeze
        private_constant :SUFFIX_INDEX_REGEX
        INDEX_REGEX = /\d+/.freeze
        private_constant :INDEX_REGEX

        def filter_indexed_lets(candidates)
          candidates
            .filter { |node| indexed_let?(node) }
            .group_by { |node| let_name_stripped_index(node) }
            .values
            .filter { |lets| lets.length > cop_config['Max'] }
            .flatten
        end

        def indexed_let?(node)
          let?(node) &&
            SUFFIX_INDEX_REGEX.match?(let_name(node)) &&
            !allowed_identifier?(let_name(node).to_s) &&
            !matches_allowed_pattern?(let_name(node).to_s)
        end

        def let_name_stripped_index(node)
          let_name(node).to_s.gsub(INDEX_REGEX, '')
        end

        def cop_config_patterns_values
          Array(config.for_cop('Naming/VariableNumber')
            .fetch('AllowedPatterns', [])) +
            Array(cop_config.fetch('AllowedPatterns', []))
        end

        def allowed_identifiers
          Array(config.for_cop('Naming/VariableNumber')
            .fetch('AllowedIdentifiers', [])) +
            Array(cop_config.fetch('AllowedIdentifiers', []))
        end
      end
    end
  end
end
