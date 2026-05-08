class AddKanbanEnabledToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :kanban_enabled, :boolean, default: true, null: false
  end
end
