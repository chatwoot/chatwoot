class CreateKanbanCards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_cards do |t|
      t.references :kanban_column, null: false, foreign_key: true
      t.references :kanban_board, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.decimal :potential_value, precision: 15, scale: 2
      t.text :notes
      t.float :position, null: false, default: 1.0
      t.timestamps
    end

    add_index :kanban_cards, [:kanban_board_id, :contact_id], unique: true
    add_index :kanban_cards, [:kanban_column_id, :position]
  end
end
