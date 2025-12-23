# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Use consistent metadata style.
      #
      # This cop does not support autocorrection in the case of
      # `EnforcedStyle: hash` where the trailing metadata type is ambiguous.
      # (e.g. `describe 'Something', :a, b`)
      #
      # @example EnforcedStyle: symbol (default)
      #   # bad
      #   describe 'Something', a: true
      #
      #   # good
      #   describe 'Something', :a
      #
      # @example EnforcedStyle: hash
      #   # bad
      #   describe 'Something', :a
      #
      #   # good
      #   describe 'Something', a: true
      class MetadataStyle < Base # rubocop:disable Metrics/ClassLength
        extend AutoCorrector

        include ConfigurableEnforcedStyle
        include Metadata
        include RangeHelp

        # @!method extract_metadata_hash(node)
        def_node_matcher :extract_metadata_hash, <<~PATTERN
          (send _ _ _ ... $hash)
        PATTERN

        # @!method match_boolean_metadata_pair?(node)
        def_node_matcher :match_boolean_metadata_pair?, <<~PATTERN
          (pair sym true)
        PATTERN

        # @!method match_ambiguous_trailing_metadata?(node)
        def_node_matcher :match_ambiguous_trailing_metadata?, <<~PATTERN
          (send _ _ _ ... !{hash sym})
        PATTERN

        def on_metadata(symbols, hash)
          symbols.each do |symbol|
            on_metadata_symbol(symbol) if symbol.sym_type?
          end

          return unless hash

          hash.pairs.each do |pair|
            on_metadata_pair(pair)
          end
        end

        private

        def autocorrect_pair(corrector, node)
          remove_pair(corrector, node)
          insert_symbol(corrector, node)
        end

        def autocorrect_symbol(corrector, node)
          return if match_ambiguous_trailing_metadata?(node.parent)

          remove_symbol(corrector, node)
          insert_pair(corrector, node)
        end

        def bad_metadata_pair?(node)
          style == :symbol && match_boolean_metadata_pair?(node)
        end

        def bad_metadata_symbol?(_node)
          style == :hash
        end

        def format_symbol_to_pair_source(node)
          "#{node.value}: true"
        end

        def insert_pair(corrector, node)
          hash_node = extract_metadata_hash(node.parent)
          if hash_node.nil?
            insert_pair_as_last_argument(corrector, node)
          elsif hash_node.pairs.any?
            insert_pair_to_non_empty_hash_metadata(corrector, node, hash_node)
          else
            insert_pair_to_empty_hash_metadata(corrector, node, hash_node)
          end
        end

        def insert_pair_as_last_argument(corrector, node)
          corrector.insert_before(
            node.parent.location.end || node.parent.source_range.with(
              begin_pos: node.parent.source_range.end_pos
            ),
            ", #{format_symbol_to_pair_source(node)}"
          )
        end

        def insert_pair_to_empty_hash_metadata(corrector, node, hash_node)
          corrector.insert_after(
            hash_node.location.begin,
            " #{format_symbol_to_pair_source(node)} "
          )
        end

        def insert_pair_to_non_empty_hash_metadata(corrector, node, hash_node)
          corrector.insert_after(
            hash_node.children.last,
            ", #{format_symbol_to_pair_source(node)}"
          )
        end

        def insert_symbol(corrector, node)
          corrector.insert_after(
            node.parent.left_sibling,
            ", #{node.key.value.inspect}"
          )
        end

        def message_for_style
          format(
            'Use %<style>s style for metadata.',
            style: style
          )
        end

        def on_metadata_pair(node)
          return unless bad_metadata_pair?(node)

          add_offense(node, message: message_for_style) do |corrector|
            autocorrect_pair(corrector, node)
          end
        end

        def on_metadata_symbol(node)
          return unless bad_metadata_symbol?(node)

          add_offense(node, message: message_for_style) do |corrector|
            autocorrect_symbol(corrector, node)
          end
        end

        def remove_pair(corrector, node)
          if !node.parent.braces? || node.left_siblings.any?
            remove_pair_following(corrector, node)
          elsif node.right_siblings.any?
            remove_pair_preceding(corrector, node)
          else
            corrector.remove(node)
          end
        end

        def remove_pair_following(corrector, node)
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.source_range,
                side: :left
              ),
              :left
            )
          )
        end

        def remove_pair_preceding(corrector, node)
          corrector.remove(
            range_with_surrounding_space(
              range_with_surrounding_comma(
                node.source_range,
                :right
              ),
              side: :right
            )
          )
        end

        def remove_symbol(corrector, node)
          corrector.remove(
            range_with_surrounding_comma(
              range_with_surrounding_space(
                node.source_range,
                side: :left
              ),
              :left
            )
          )
        end
      end
    end
  end
end
