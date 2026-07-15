class CreateKanbanCards < ActiveRecord::Migration[7.1]
  def change
    create_table :kanban_cards do |t|
      t.references :account, null: false, foreign_key: true
      t.references :kanban_board, null: false, foreign_key: true
      t.references :kanban_column, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.integer :position, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :kanban_cards, [:kanban_column_id, :position]
    add_index :kanban_cards, [:kanban_board_id, :conversation_id], unique: true
  end
end
