class CreateChatwootKanbanChecklistItems < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_checklist_items do |t|
      t.references :card, null: false,
                   foreign_key: { to_table: :chatwoot_kanban_cards, on_delete: :cascade },
                   index: true
      t.string  :title,     null: false, limit: 200
      t.boolean :completed, null: false, default: false
      t.integer :position,  null: false, default: 0
      t.bigint  :completed_by_id
      t.datetime :completed_at
      t.timestamps
    end

    add_index :chatwoot_kanban_checklist_items, [:card_id, :position]
  end
end
