# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Enforces the use of the `comment` option when adding a new table or column
      # to the database during a migration.
      #
      # @example
      #   # bad (no comment for a new column or table)
      #   add_column :table, :column, :integer
      #
      #   create_table :table do |t|
      #     t.type :column
      #   end
      #
      #   # good
      #   add_column :table, :column, :integer, comment: 'Number of offenses'
      #
      #   create_table :table, comment: 'Table of offenses data' do |t|
      #     t.type :column, comment: 'Number of offenses'
      #   end
      #
      class SchemaComment < Base
        include ActiveRecordMigrationsHelper
        include MigrationsHelper

        COLUMN_MSG = 'New database column without `comment`.'
        TABLE_MSG = 'New database table without `comment`.'
        RESTRICT_ON_SEND = %i[add_column create_table].freeze
        CREATE_TABLE_COLUMN_METHODS = Set[
          *(
            RAILS_ABSTRACT_SCHEMA_DEFINITIONS |
            RAILS_ABSTRACT_SCHEMA_DEFINITIONS_HELPERS |
            POSTGRES_SCHEMA_DEFINITIONS |
            MYSQL_SCHEMA_DEFINITIONS
          )
        ].freeze

        # @!method comment_present?(node)
        def_node_matcher :comment_present?, <<~PATTERN
          (hash <(pair {(sym :comment) (str "comment")} !{nil (str blank?)}) ...>)
        PATTERN

        # @!method add_column?(node)
        def_node_matcher :add_column?, <<~PATTERN
          (send nil? :add_column _table _column _type _?)
        PATTERN

        # @!method add_column_with_comment?(node)
        def_node_matcher :add_column_with_comment?, <<~PATTERN
          (send nil? :add_column _table _column _type #comment_present?)
        PATTERN

        # @!method create_table?(node)
        def_node_matcher :create_table?, <<~PATTERN
          (send nil? :create_table _table _?)
        PATTERN

        # @!method create_table?(node)
        def_node_matcher :create_table_with_comment?, <<~PATTERN
          (send nil? :create_table _table #comment_present? ...)
        PATTERN

        # @!method t_column?(node)
        def_node_matcher :t_column?, <<~PATTERN
          (send _var CREATE_TABLE_COLUMN_METHODS ...)
        PATTERN

        # @!method t_column_with_comment?(node)
        def_node_matcher :t_column_with_comment?, <<~PATTERN
          (send _var CREATE_TABLE_COLUMN_METHODS _column _type? #comment_present?)
        PATTERN

        def on_send(node)
          if add_column_without_comment?(node)
            add_offense(node, message: COLUMN_MSG)
          elsif create_table_without_comment?(node)
            add_offense(node, message: TABLE_MSG)
          elsif create_table_with_block?(node.parent)
            check_column_within_create_table_block(node.parent.body)
          end
        end

        private

        def check_column_within_create_table_block(node)
          if node.begin_type?
            node.child_nodes.each do |child_node|
              add_offense(child_node, message: COLUMN_MSG) if t_column_without_comment?(child_node)
            end
          elsif t_column_without_comment?(node)
            add_offense(node, message: COLUMN_MSG)
          end
        end

        def add_column_without_comment?(node)
          add_column?(node) && !add_column_with_comment?(node)
        end

        def create_table_without_comment?(node)
          create_table?(node) && !create_table_with_comment?(node)
        end

        def t_column_without_comment?(node)
          t_column?(node) && !t_column_with_comment?(node)
        end
      end
    end
  end
end
