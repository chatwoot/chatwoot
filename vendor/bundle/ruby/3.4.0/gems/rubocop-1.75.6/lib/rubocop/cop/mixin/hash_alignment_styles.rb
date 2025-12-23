# frozen_string_literal: true

module RuboCop
  module Cop
    # Common functionality for checking hash alignment.
    module HashAlignmentStyles
      # Handles calculation of deltas when the enforced style is 'key'.
      class KeyAlignment
        def checkable_layout?(_node)
          true
        end

        def deltas_for_first_pair(first_pair)
          {
            separator: separator_delta(first_pair),
            value: value_delta(first_pair)
          }
        end

        def deltas(first_pair, current_pair)
          if Util.begins_its_line?(current_pair.source_range)
            key_delta = first_pair.key_delta(current_pair)
            separator_delta = separator_delta(current_pair)
            value_delta = value_delta(current_pair)

            { key: key_delta, separator: separator_delta, value: value_delta }
          else
            {}
          end
        end

        private

        def separator_delta(pair)
          if pair.hash_rocket?
            correct_separator_column = pair.key.source_range.end.column + 1
            actual_separator_column = pair.loc.operator.column

            correct_separator_column - actual_separator_column
          else
            0
          end
        end

        def value_delta(pair)
          return 0 if pair.value_on_new_line? || pair.value_omission?

          correct_value_column = pair.loc.operator.end.column + 1
          actual_value_column = pair.value.loc.column

          correct_value_column - actual_value_column
        end
      end

      # Common functionality for checking alignment of hash values.
      module ValueAlignment
        def checkable_layout?(node)
          !node.pairs_on_same_line? && !node.mixed_delimiters?
        end

        def deltas(first_pair, current_pair)
          key_delta = key_delta(first_pair, current_pair)
          separator_delta = separator_delta(first_pair, current_pair, key_delta)
          value_delta = value_delta(first_pair, current_pair) - key_delta - separator_delta

          { key: key_delta, separator: separator_delta, value: value_delta }
        end

        private

        def separator_delta(first_pair, current_pair, key_delta)
          if current_pair.hash_rocket?
            hash_rocket_delta(first_pair, current_pair) - key_delta
          else
            0
          end
        end
      end

      # Handles calculation of deltas when the enforced style is 'table'.
      class TableAlignment
        include ValueAlignment

        def deltas_for_first_pair(first_pair)
          separator_delta = separator_delta(first_pair, first_pair, 0)
          {
            separator: separator_delta,
            value: value_delta(first_pair, first_pair) - separator_delta
          }
        end

        private

        def key_delta(first_pair, current_pair)
          first_pair.key_delta(current_pair)
        end

        def hash_rocket_delta(first_pair, current_pair)
          first_pair.loc.column + max_key_width(first_pair.parent) + 1 -
            current_pair.loc.operator.column
        end

        def value_delta(first_pair, current_pair)
          correct_value_column = first_pair.key.loc.column +
                                 max_key_width(first_pair.parent) +
                                 max_delimiter_width(first_pair.parent)

          current_pair.value_omission? ? 0 : correct_value_column - current_pair.value.loc.column
        end

        def max_key_width(hash_node)
          hash_node.keys.map { |key| key.source.length }.max
        end

        def max_delimiter_width(hash_node)
          hash_node.pairs.map { |pair| pair.delimiter(true).length }.max
        end
      end

      # Handles calculation of deltas when the enforced style is 'separator'.
      class SeparatorAlignment
        include ValueAlignment

        def deltas_for_first_pair(_first_pair)
          {}
        end

        private

        def key_delta(first_pair, current_pair)
          first_pair.key_delta(current_pair, :right)
        end

        def hash_rocket_delta(first_pair, current_pair)
          first_pair.delimiter_delta(current_pair)
        end

        def value_delta(first_pair, current_pair)
          current_pair.value_omission? ? 0 : first_pair.value_delta(current_pair)
        end
      end

      # Handles calculation of deltas for `kwsplat` nodes.
      # This is a special case that just ensures the kwsplat is aligned with the rest of the hash
      # since a `kwsplat` does not have a key, separator or value.
      class KeywordSplatAlignment
        def deltas(first_pair, current_pair)
          if Util.begins_its_line?(current_pair.source_range)
            { key: first_pair.key_delta(current_pair) }
          else
            {}
          end
        end
      end
    end
  end
end
