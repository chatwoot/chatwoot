# frozen_string_literal: true

module RuboCop
  module Cop
    module Metrics
      module Utils
        # Used to identify iterating blocks like `.map{}` and `.map(&:...)`
        module IteratingBlock
          enumerable = %i[
            all? any? chain chunk chunk_while collect collect_concat count cycle
            detect drop drop_while each each_cons each_entry each_slice
            each_with_index each_with_object entries filter filter_map find
            find_all find_index flat_map grep grep_v group_by inject lazy map
            max max_by min min_by minmax minmax_by none? one? partition reduce
            reject reverse_each select slice_after slice_before slice_when sort
            sort_by sum take take_while tally to_h uniq zip
          ]

          enumerator = %i[with_index with_object]

          array = %i[
            bsearch bsearch_index collect! combination d_permutation delete_if
            each_index keep_if map! permutation product reject! repeat
            repeated_combination select! sort sort! sort_by sort_by
          ]

          hash = %i[
            each_key each_pair each_value fetch fetch_values has_key? merge
            merge! transform_keys transform_keys! transform_values
            transform_values!
          ]

          KNOWN_ITERATING_METHODS = (Set.new(enumerable) + enumerator + array + hash).freeze

          # Returns the name of the method called with a block
          # if node is a block node, or a block-pass node.
          def block_method_name(node)
            case node.type
            when :block
              node.method_name
            when :block_pass
              node.parent.method_name
            end
          end

          # Returns true iff name is a known iterating type (e.g. :each, :transform_values)
          def iterating_method?(name)
            KNOWN_ITERATING_METHODS.include? name
          end

          # Returns nil if node is neither a block node or a block-pass node.
          # Otherwise returns true/false if method call is a known iterating call
          def iterating_block?(node)
            name = block_method_name(node)
            name && iterating_method?(name)
          end
        end
      end
    end
  end
end
