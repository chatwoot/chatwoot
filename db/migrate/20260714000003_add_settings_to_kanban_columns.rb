class AddSettingsToKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_columns, :description, :text
    add_column :kanban_columns, :win_probability, :decimal, precision: 5, scale: 2, null: false, default: 100
  end
end
