# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for migrations using `add_column` that have an `index`
      # key. `add_column` does not accept `index`, but also does not raise an
      # error for extra keys, so it is possible to mistakenly add the key without
      # realizing it will not actually add an index.
      #
      # @example
      #   # bad (will not add an index)
      #   add_column :table, :column, :integer, index: true
      #
      #   # good
      #   add_column :table, :column, :integer
      #   add_index :table, :column
      #
      class AddColumnIndex < Base
        extend AutoCorrector
        include RangeHelp
        include MigrationsHelper

        MSG = '`add_column` does not accept an `index` key, use `add_index` instead.'
        RESTRICT_ON_SEND = %i[add_column].freeze

        # @!method add_column_with_index(node)
        def_node_matcher :add_column_with_index, <<~PATTERN
          (
            send nil? :add_column $_table $_column
              <(hash <$(pair {(sym :index) (str "index")} $_) ...>) ...>
          )
        PATTERN

        def on_send(node)
          table, column, pair, value = add_column_with_index(node)
          return unless pair

          add_offense(pair) do |corrector|
            corrector.remove(index_range(pair))

            add_index = "add_index #{table.source}, #{column.source}"
            add_index_opts = ''

            if value.hash_type?
              hash = value.source_range.adjust(begin_pos: 1, end_pos: -1).source.strip
              add_index_opts = ", #{hash}"
            end

            corrector.insert_after(node, "\n#{add_index}#{add_index_opts}")
          end
        end

        private

        def index_range(pair_node)
          range_with_surrounding_comma(range_with_surrounding_space(pair_node.source_range, side: :left), :left)
        end
      end
    end
  end
end
