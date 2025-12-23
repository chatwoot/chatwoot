# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks for add_column calls with a NOT NULL constraint without a default
      # value.
      #
      # This cop only applies when adding a column to an existing table, since
      # existing records will not have a value for the new column. New tables
      # can freely use NOT NULL columns without defaults, since there are no
      # records that could violate the constraint.
      #
      # If you need to add a NOT NULL column to an existing table, you must add
      # it as nullable first, back-fill the data, and then use
      # `change_column_null`. Alternatively, you could add the column with a
      # default first to have the database automatically backfill existing rows,
      # and then use `change_column_default` to remove the default.
      #
      # `TEXT` cannot have a default value in MySQL.
      # The cop will automatically detect an adapter from `development`
      # environment in `config/database.yml` or the environment variable
      # `DATABASE_URL` when the `Database` option is not set. If the database
      # is MySQL, this cop ignores offenses for `TEXT` columns.
      #
      # @example
      #   # bad
      #   add_column :users, :name, :string, null: false
      #   add_reference :products, :category, null: false
      #   change_table :users do |t|
      #     t.string :name, null: false
      #   end
      #
      #   # good
      #   add_column :users, :name, :string, null: true
      #   add_column :users, :name, :string, null: false, default: ''
      #   change_table :users do |t|
      #     t.string :name, null: false, default: ''
      #   end
      #   add_reference :products, :category
      #   change_column_null :products, :category_id, false
      class NotNullColumn < Base
        include DatabaseTypeResolvable
        include MigrationsHelper

        MSG = 'Do not add a NOT NULL column without a default value.'
        RESTRICT_ON_SEND = %i[add_column add_reference].freeze

        VIRTUAL_TYPE_VALUES = [:virtual, 'virtual'].freeze
        TEXT_TYPE_VALUES = [:text, 'text'].freeze

        def_node_matcher :add_not_null_column?, <<~PATTERN
          (send nil? :add_column _ _ $_ (hash $...))
        PATTERN

        def_node_matcher :add_not_null_reference?, <<~PATTERN
          (send nil? :add_reference _ _ (hash $...))
        PATTERN

        def_node_matcher :change_table?, <<~PATTERN
          (block (send nil? :change_table ...) (args (arg $_)) _)
        PATTERN

        def_node_matcher :add_not_null_column_in_change_table?, <<~PATTERN
          (send (lvar $_) :column _ $_ (hash $...))
        PATTERN

        def_node_matcher :add_not_null_column_via_shortcut_in_change_table?, <<~PATTERN
          (send (lvar $_) $_ _ (hash $...))
        PATTERN

        def_node_matcher :add_not_null_reference_in_change_table?, <<~PATTERN
          (send (lvar $_) :add_reference _ _ (hash $...))
        PATTERN

        def_node_matcher :null_false?, <<~PATTERN
          (pair (sym :null) (false))
        PATTERN

        def_node_matcher :default_option?, <<~PATTERN
          (pair (sym :default) !nil)
        PATTERN

        def on_send(node)
          check_add_column(node)
          check_add_reference(node)
        end

        def on_block(node)
          check_change_table(node)
        end
        alias on_numblock on_block

        private

        def check_column(type, pairs)
          if type.respond_to?(:value)
            return if VIRTUAL_TYPE_VALUES.include?(type.value)
            return if TEXT_TYPE_VALUES.include?(type.value) && database == MYSQL
          end

          check_pairs(pairs)
        end

        def check_add_column(node)
          add_not_null_column?(node) do |type, pairs|
            check_column(type, pairs)
          end
        end

        def check_add_reference(node)
          add_not_null_reference?(node) do |pairs|
            check_pairs(pairs)
          end
        end

        def check_add_column_in_change_table(node, table)
          add_not_null_column_in_change_table?(node) do |receiver, type, pairs|
            next unless receiver == table

            check_column(type, pairs)
          end
        end

        def check_add_column_via_shortcut_in_change_table(node, table)
          add_not_null_column_via_shortcut_in_change_table?(node) do |receiver, type, pairs|
            next unless receiver == table

            check_column(type, pairs)
          end
        end

        def check_add_reference_in_change_table(node, table)
          add_not_null_reference_in_change_table?(node) do |receiver, pairs|
            next unless receiver == table

            check_pairs(pairs)
          end
        end

        def check_change_table(node)
          change_table?(node) do |table|
            next unless node.body

            children = node.body.begin_type? ? node.body.children : [node.body]
            children.each do |child|
              check_add_column_in_change_table(child, table)
              check_add_column_via_shortcut_in_change_table(child, table)
              check_add_reference_in_change_table(child, table)
            end
          end
        end

        def check_pairs(pairs)
          return if pairs.any? { |pair| default_option?(pair) }

          null_false = pairs.find { |pair| null_false?(pair) }
          return unless null_false

          add_offense(null_false)
        end
      end
    end
  end
end
