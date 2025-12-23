# frozen_string_literal: true

module RuboCop
  module Cop
    module Rails
      # Checks whether the change method of the migration file is
      # reversible.
      #
      # @example
      #   # bad
      #   def change
      #     change_table :users do |t|
      #       t.remove :name
      #     end
      #   end
      #
      #   # good
      #   def change
      #     change_table :users do |t|
      #       t.remove :name, type: :string
      #     end
      #   end
      #
      #   # good
      #   def change
      #     create_table :users do |t|
      #       t.string :name
      #     end
      #   end
      #
      # @example
      #   # drop_table
      #
      #   # bad
      #   def change
      #     drop_table :users
      #   end
      #
      #   # good
      #   def change
      #     drop_table :users do |t|
      #       t.string :name
      #     end
      #   end
      #
      # @example
      #   # change_column_default
      #
      #   # bad
      #   def change
      #     change_column_default(:suppliers, :qualification, 'new')
      #   end
      #
      #   # good
      #   def change
      #     change_column_default(:posts, :state, from: nil, to: "draft")
      #   end
      #
      # @example
      #   # remove_column
      #
      #   # bad
      #   def change
      #     remove_column(:suppliers, :qualification)
      #   end
      #
      #   # good
      #   def change
      #     remove_column(:suppliers, :qualification, :string)
      #   end
      #
      # @example
      #   # remove_foreign_key
      #
      #   # bad
      #   def change
      #     remove_foreign_key :accounts, column: :owner_id
      #   end
      #
      #   # good
      #   def change
      #     remove_foreign_key :accounts, :branches
      #   end
      #
      #   # good
      #   def change
      #     remove_foreign_key :accounts, to_table: :branches
      #   end
      #
      # @example
      #   # change_table
      #
      #   # bad
      #   def change
      #     change_table :users do |t|
      #       t.remove :name
      #       t.change_default :authorized, 1
      #       t.change :price, :string
      #     end
      #   end
      #
      #   # good
      #   def change
      #     change_table :users do |t|
      #       t.string :name
      #     end
      #   end
      #
      # @example
      #   # remove_columns
      #
      #   # bad
      #   def change
      #     remove_columns :users, :name, :email
      #   end
      #
      #   # good
      #   def change
      #     reversible do |dir|
      #       dir.up do
      #         remove_columns :users, :name, :email
      #       end
      #
      #       dir.down do
      #         add_column :users, :name, :string
      #         add_column :users, :email, :string
      #       end
      #     end
      #   end
      #
      #   # good (Rails >= 6.1, see https://github.com/rails/rails/pull/36589)
      #   def change
      #     remove_columns :users, :name, :email, type: :string
      #   end
      #
      # @example
      #   # remove_index
      #
      #   # bad
      #   def change
      #     remove_index :users, name: :index_users_on_email
      #   end
      #
      #   # good
      #   def change
      #     remove_index :users, :email
      #   end
      #
      #   # good
      #   def change
      #     remove_index :users, column: :email
      #   end
      class ReversibleMigration < Base
        include MigrationsHelper

        MSG = '%<action>s is not reversible.'

        def_node_matcher :irreversible_schema_statement_call, <<~PATTERN
          (send nil? ${:change_column :execute} ...)
        PATTERN

        def_node_matcher :drop_table_call, <<~PATTERN
          (send nil? :drop_table ...)
        PATTERN

        def_node_matcher :remove_column_call, <<~PATTERN
          (send nil? :remove_column $...)
        PATTERN

        def_node_matcher :remove_foreign_key_call, <<~PATTERN
          (send nil? :remove_foreign_key _ $_)
        PATTERN

        def_node_matcher :change_table_call, <<~PATTERN
          (send nil? :change_table $_ ...)
        PATTERN

        def_node_matcher :remove_columns_call, <<~PATTERN
          (send nil? :remove_columns ... $_)
        PATTERN

        def_node_matcher :remove_index_call, <<~PATTERN
          (send nil? :remove_index _ $_)
        PATTERN

        def on_send(node)
          return unless in_migration?(node) && within_change_method?(node)
          return if within_reversible_or_up_only_block?(node)

          check_irreversible_schema_statement_node(node)
          check_drop_table_node(node)
          check_reversible_hash_node(node)
          check_remove_column_node(node)
          check_remove_foreign_key_node(node)
          check_remove_columns_node(node)
          check_remove_index_node(node)
        end

        def on_block(node)
          return unless in_migration?(node) && within_change_method?(node)
          return if within_reversible_or_up_only_block?(node)
          return if node.body.nil?

          check_change_table_node(node.send_node, node.body)
        end

        alias on_numblock on_block
        alias on_itblock on_block

        private

        def check_irreversible_schema_statement_node(node)
          irreversible_schema_statement_call(node) do |method_name|
            add_offense(node, message: format(MSG, action: method_name))
          end
        end

        def check_drop_table_node(node)
          return unless (last_argument = node.last_argument)

          drop_table_call(node) do
            unless node.parent.any_block_type? || last_argument.block_pass_type?
              add_offense(node, message: format(MSG, action: 'drop_table(without block)'))
            end
          end
        end

        def check_reversible_hash_node(node)
          return if reversible_change_table_call?(node)

          add_offense(node, message: format(MSG, action: "#{node.method_name}(without :from and :to)"))
        end

        def check_remove_column_node(node)
          remove_column_call(node) do |args|
            add_offense(node, message: format(MSG, action: 'remove_column(without type)')) if args.to_a.size < 3
          end
        end

        def check_remove_foreign_key_node(node)
          remove_foreign_key_call(node) do |arg|
            if arg.hash_type? && !all_hash_key?(arg, :to_table)
              add_offense(node, message: format(MSG, action: 'remove_foreign_key(without table)'))
            end
          end
        end

        def check_change_table_node(node, block)
          change_table_call(node) do |arg|
            if block.send_type?
              check_change_table_offense(arg, block)
            else
              block.each_child_node(:send) do |child_node|
                check_change_table_offense(arg, child_node)
              end
            end
          end
        end

        def check_remove_columns_node(node)
          remove_columns_call(node) do |args|
            unless all_hash_key?(args, :type) && target_rails_version >= 6.1
              action = target_rails_version >= 6.1 ? 'remove_columns(without type)' : 'remove_columns'

              add_offense(node, message: format(MSG, action: action))
            end
          end
        end

        def check_remove_index_node(node)
          remove_index_call(node) do |args|
            if args.hash_type? && !all_hash_key?(args, :column)
              add_offense(node, message: format(MSG, action: 'remove_index(without column)'))
            end
          end
        end

        def check_change_table_offense(receiver, node)
          method_name = node.method_name
          return if receiver != node.receiver && reversible_change_table_call?(node)

          action = if method_name == :remove
                     target_rails_version >= 6.1 ? 't.remove (without type)' : 't.remove'
                   else
                     "change_table(with #{method_name})"
                   end

          add_offense(node, message: format(MSG, action: action))
        end

        def reversible_change_table_call?(node)
          case node.method_name
          when :change
            false
          when :remove
            target_rails_version >= 6.1 && all_hash_key?(node.last_argument, :type)
          when :change_default, :change_column_default, :change_table_comment,
               :change_column_comment
            all_hash_key?(node.last_argument, :from, :to)
          else
            true
          end
        end

        def within_change_method?(node)
          node.each_ancestor(:def).any? do |ancestor|
            ancestor.method?(:change)
          end
        end

        def within_reversible_or_up_only_block?(node)
          node.each_ancestor(:block).any? do |ancestor|
            (ancestor.block_type? && ancestor.method?(:reversible)) || ancestor.method?(:up_only)
          end
        end

        def all_hash_key?(args, *keys)
          return false unless args&.hash_type?

          hash_keys = args.keys.map do |key|
            key.children.first.to_sym
          end

          (hash_keys & keys).sort == keys
        end
      end
    end
  end
end
