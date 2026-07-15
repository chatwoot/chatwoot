class CreateKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_columns do |t|
      t.references :account, null: false, foreign_key: true
      t.references :kanban_board, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :kanban_columns, [:kanban_board_id, :position]
    add_index :kanban_columns, [:kanban_board_id, :name], unique: true
  end
end
