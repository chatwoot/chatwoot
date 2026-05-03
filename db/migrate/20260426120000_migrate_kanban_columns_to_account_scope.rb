class MigrateKanbanColumnsToAccountScope < ActiveRecord::Migration[7.1]
  def up
    add_column :kanban_columns, :account_id, :bigint

    execute <<-SQL
      UPDATE kanban_columns
      SET account_id = kanban_boards.account_id
      FROM kanban_boards
      WHERE kanban_columns.kanban_board_id = kanban_boards.id
    SQL

    change_column_null :kanban_columns, :account_id, false
    add_foreign_key :kanban_columns, :accounts
    add_index :kanban_columns, :account_id
    add_index :kanban_columns, [:account_id, :position]

    remove_foreign_key :kanban_columns, :kanban_boards
    remove_index :kanban_columns, name: 'index_kanban_columns_on_kanban_board_id'
    remove_index :kanban_columns, name: 'index_kanban_columns_on_kanban_board_id_and_position'
    remove_column :kanban_columns, :kanban_board_id
  end

  def down
    add_column :kanban_columns, :kanban_board_id, :bigint
    add_foreign_key :kanban_columns, :kanban_boards
    add_index :kanban_columns, :kanban_board_id
    add_index :kanban_columns, [:kanban_board_id, :position]

    remove_foreign_key :kanban_columns, :accounts
    remove_index :kanban_columns, :account_id
    remove_index :kanban_columns, [:account_id, :position]
    remove_column :kanban_columns, :account_id
  end
end
