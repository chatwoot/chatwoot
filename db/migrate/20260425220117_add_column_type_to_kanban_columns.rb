class AddColumnTypeToKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_columns, :column_type, :integer, default: 0, null: false
  end
end
