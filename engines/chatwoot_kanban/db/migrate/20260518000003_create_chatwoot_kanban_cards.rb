class CreateChatwootKanbanCards < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_cards do |t|
      t.references :column, null: false,
                   foreign_key: { to_table: :chatwoot_kanban_columns, on_delete: :cascade },
                   index: true
      # conversation_id is nullable: cards can be standalone internal tasks
      t.bigint :conversation_id
      t.string :title,       null: false, limit: 200
      t.text   :description
      t.integer :position,   null: false, default: 0
      t.integer :priority,   null: false, default: 0
      t.datetime :due_at
      t.bigint :assignee_id
      t.jsonb  :metadata,    null: false, default: {}
      t.bigint :created_by_id
      t.timestamps
    end

    add_index :chatwoot_kanban_cards, [:column_id, :position]
    add_index :chatwoot_kanban_cards, :conversation_id
    add_index :chatwoot_kanban_cards, :assignee_id
    add_index :chatwoot_kanban_cards, :due_at
  end
end
