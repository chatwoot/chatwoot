class CreateKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_columns do |t|
      t.references :kanban_board, null: false, foreign_key: true
      t.string :name, null: false
      t.float :position, null: false, default: 1.0
      t.string :color
      t.timestamps
    end

    add_index :kanban_columns, [:kanban_board_id, :position]
  end
end
