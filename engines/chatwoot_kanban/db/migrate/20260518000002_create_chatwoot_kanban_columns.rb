class CreateChatwootKanbanColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_columns do |t|
      t.references :board, null: false,
                   foreign_key: { to_table: :chatwoot_kanban_boards, on_delete: :cascade },
                   index: true
      t.string  :name,     null: false, limit: 80
      t.integer :position, null: false, default: 0
      t.string  :color,    limit: 16
      t.integer :wip_limit
      t.timestamps
    end

    add_index :chatwoot_kanban_columns, [:board_id, :position]
  end
end
