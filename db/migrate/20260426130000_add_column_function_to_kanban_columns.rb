class AddColumnFunctionToKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_columns, :column_function, :integer, default: 0, null: false
  end
end
