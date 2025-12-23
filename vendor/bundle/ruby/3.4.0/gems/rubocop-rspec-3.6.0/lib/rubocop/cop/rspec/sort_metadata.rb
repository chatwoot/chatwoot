# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Sort RSpec metadata alphabetically.
      #
      # Only the trailing metadata is sorted.
      #
      # @example
      #   # bad
      #   describe 'Something', :b, :a
      #   context 'Something', foo: 'bar', baz: true
      #   it 'works', :b, :a, foo: 'bar', baz: true
      #
      #   # good
      #   describe 'Something', :a, :b
      #   context 'Something', baz: true, foo: 'bar'
      #   it 'works', :a, :b, baz: true, foo: 'bar'
      #
      #   # good, trailing metadata is sorted
      #   describe 'Something', 'description', :a, :b, :z
      #   context 'Something', :z, variable, :a, :b
      class SortMetadata < Base
        extend AutoCorrector
        include Metadata
        include RangeHelp

        MSG = 'Sort metadata alphabetically.'

        # @!method match_ambiguous_trailing_metadata?(node)
        def_node_matcher :match_ambiguous_trailing_metadata?, <<~PATTERN
          (send _ _ _ ... !{hash sym str dstr xstr})
        PATTERN

        def on_metadata(args, hash)
          pairs = hash&.pairs || []
          symbols = trailing_symbols(args)
          return if sorted?(symbols, pairs)

          crime_scene = crime_scene(symbols, pairs)
          add_offense(crime_scene) do |corrector|
            corrector.replace(crime_scene, replacement(symbols, pairs))
          end
        end

        private

        def trailing_symbols(args)
          args = args[...-1] if last_arg_could_be_a_hash?(args)
          args.reverse.take_while(&:sym_type?).reverse
        end

        def last_arg_could_be_a_hash?(args)
          args.last && match_ambiguous_trailing_metadata?(args.last.parent)
        end

        def crime_scene(symbols, pairs)
          metadata = symbols + pairs

          range_between(
            metadata.first.source_range.begin_pos,
            metadata.last.source_range.end_pos
          )
        end

        def replacement(symbols, pairs)
          (sort_symbols(symbols) + sort_pairs(pairs)).map(&:source).join(', ')
        end

        def sorted?(symbols, pairs)
          symbols == sort_symbols(symbols) && pairs == sort_pairs(pairs)
        end

        def sort_pairs(pairs)
          pairs.sort_by { |pair| pair.key.source.downcase }
        end

        def sort_symbols(symbols)
          symbols.sort_by { |symbol| symbol.value.to_s.downcase }
        end
      end
    end
  end
end
