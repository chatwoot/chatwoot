# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks whether alter queries are combinable.
      # If combinable queries are detected, it suggests to you
      # to use `change_table` with `bulk: true` instead.
      # This option causes the migration to generate a single
      # ALTER TABLE statement combining multiple column alterations.
      #
      # The `bulk` option is only supported on the MySQL and
      # the PostgreSQL (5.2 later) adapter; thus it will
      # automatically detect an adapter from `development` environment
      # in `config/database.yml` or the environment variable `DATABASE_URL`
      # when the `Database` option is not set.
      # If the adapter is not `mysql2`, `trilogy`, `postgresql`, or `postgis`,
      # this Cop ignores offenses.
      #
      # @example
      #   # bad
      #   def change
      #     add_column :users, :name, :string, null: false
      #     add_column :users, :nickname, :string
      #
      #     # ALTER TABLE `users` ADD `name` varchar(255) NOT NULL
      #     # ALTER TABLE `users` ADD `nickname` varchar(255)
      #   end
      #
      #   # good
      #   def change
      #     change_table :users, bulk: true do |t|
      #       t.string :name, null: false
      #       t.string :nickname
      #     end
      #
      #     # ALTER TABLE `users` ADD `name` varchar(255) NOT NULL,
      #     #                     ADD `nickname` varchar(255)
      #   end
      #
      # @example
      #   # bad
      #   def change
      #     change_table :users do |t|
      #       t.string :name, null: false
      #       t.string :nickname
      #     end
      #   end
      #
      #   # good
      #   def change
      #     change_table :users, bulk: true do |t|
      #       t.string :name, null: false
      #       t.string :nickname
      #     end
      #   end
      #
      #   # good
      #   # When you don't want to combine alter queries.
      #   def change
      #     change_table :users, bulk: false do |t|
      #       t.string :name, null: false
      #       t.string :nickname
      #     end
      #   end
      class BulkChangeTable < Base
        include DatabaseTypeResolvable
        include MigrationsHelper

        MSG_FOR_CHANGE_TABLE = <<~MSG.chomp
          You can combine alter queries using `bulk: true` options.
        MSG
        MSG_FOR_ALTER_METHODS = <<~MSG.chomp
          You can use `change_table :%<table>s, bulk: true` to combine alter queries.
        MSG

        MIGRATION_METHODS = %i[change up down].freeze

        COMBINABLE_TRANSFORMATIONS = %i[
          primary_key
          column
          string
          text
          integer
          bigint
          float
          decimal
          numeric
          datetime
          timestamp
          time
          date
          binary
          boolean
          json
          virtual
          remove
          change
          timestamps
          remove_timestamps
        ].freeze

        COMBINABLE_ALTER_METHODS = %i[
          add_column
          remove_column
          remove_columns
          change_column
          add_timestamps
          remove_timestamps
        ].freeze

        MYSQL_COMBINABLE_TRANSFORMATIONS = %i[rename index remove_index].freeze

        MYSQL_COMBINABLE_ALTER_METHODS = %i[rename_column add_index remove_index].freeze

        POSTGRESQL_COMBINABLE_TRANSFORMATIONS = %i[change_default].freeze
        POSTGRESQL_COMBINABLE_TRANSFORMATIONS_SINCE_6_1 = %i[change_null].freeze

        POSTGRESQL_COMBINABLE_ALTER_METHODS = %i[change_column_default].freeze
        POSTGRESQL_COMBINABLE_ALTER_METHODS_SINCE_6_1 = %i[change_column_null].freeze

        def on_def(node)
          return unless support_bulk_alter?
          return unless MIGRATION_METHODS.include?(node.method_name)
          return unless node.body

          recorder = AlterMethodsRecorder.new

          node.body.child_nodes.each do |child_node|
            if call_to_combinable_alter_method? child_node
              recorder.process(child_node)
            else
              recorder.flush
            end
          end

          recorder.offensive_nodes.each { |n| add_offense_for_alter_methods(n) }
        end

        def on_send(node)
          return unless support_bulk_alter?
          return unless node.command?(:change_table)
          return if include_bulk_options?(node)
          return unless (body = node.block_node&.body)

          send_nodes = send_nodes_from_change_table_block(body)

          add_offense_for_change_table(node) if count_transformations(send_nodes) > 1
        end

        private

        def send_nodes_from_change_table_block(body)
          if body.send_type?
            [body]
          else
            body.each_child_node(:send).to_a
          end
        end

        def count_transformations(send_nodes)
          send_nodes.sum do |node|
            if node.method?(:remove)
              node.arguments.count { |arg| !arg.hash_type? }
            else
              combinable_transformations.include?(node.method_name) ? 1 : 0
            end
          end
        end

        # @param node [RuboCop::AST::SendNode] (send nil? :change_table ...)
        def include_bulk_options?(node)
          # arguments: [{(sym :table)(str "table")} (hash (pair (sym :bulk) _))]
          options = node.arguments[1]
          return false unless options

          options.hash_type? && options.keys.any? { |key| key.sym_type? && key.value == :bulk }
        end

        def support_bulk_alter?
          case database
          when MYSQL
            true
          when POSTGRESQL
            # Add bulk alter support for PostgreSQL in 5.2.0
            # See: https://github.com/rails/rails/pull/31331
            target_rails_version >= 5.2
          else
            false
          end
        end

        def call_to_combinable_alter_method?(child_node)
          child_node.send_type? && combinable_alter_methods.include?(child_node.method_name)
        end

        def combinable_alter_methods
          case database
          when MYSQL
            COMBINABLE_ALTER_METHODS + MYSQL_COMBINABLE_ALTER_METHODS
          when POSTGRESQL
            result = COMBINABLE_ALTER_METHODS + POSTGRESQL_COMBINABLE_ALTER_METHODS
            result += POSTGRESQL_COMBINABLE_ALTER_METHODS_SINCE_6_1 if target_rails_version >= 6.1
            result
          end
        end

        def combinable_transformations
          case database
          when MYSQL
            COMBINABLE_TRANSFORMATIONS + MYSQL_COMBINABLE_TRANSFORMATIONS
          when POSTGRESQL
            result = COMBINABLE_TRANSFORMATIONS + POSTGRESQL_COMBINABLE_TRANSFORMATIONS
            result += POSTGRESQL_COMBINABLE_TRANSFORMATIONS_SINCE_6_1 if target_rails_version >= 6.1
            result
          end
        end

        # @param node [RuboCop::AST::SendNode]
        def add_offense_for_alter_methods(node)
          # arguments: [{(sym :table)(str "table")} ...]
          table_node = node.first_argument
          return unless table_node.is_a? RuboCop::AST::BasicLiteralNode

          message = format(MSG_FOR_ALTER_METHODS, table: table_node.value)
          add_offense(node, message: message)
        end

        # @param node [RuboCop::AST::SendNode]
        def add_offense_for_change_table(node)
          add_offense(node, message: MSG_FOR_CHANGE_TABLE)
        end

        # Record combinable alter methods and register offensive nodes.
        class AlterMethodsRecorder
          def initialize
            @nodes = []
            @offensive_nodes = []
          end

          # @param new_node [RuboCop::AST::SendNode]
          def process(new_node)
            # arguments: [{(sym :table)(str "table")} ...]
            table_node = new_node.first_argument
            if table_node.is_a? RuboCop::AST::BasicLiteralNode
              flush unless @nodes.all? do |node|
                node.first_argument.value.to_s == table_node.value.to_s
              end
              @nodes << new_node
            else
              flush
            end
          end

          def flush
            @offensive_nodes << @nodes.first if @nodes.size > 1
            @nodes = []
          end

          def offensive_nodes
            flush
            @offensive_nodes
          end
        end
      end
    end
  end
end
