class CreateChatwootKanbanComments < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_comments do |t|
      t.references :card, null: false,
                   foreign_key: { to_table: :chatwoot_kanban_cards, on_delete: :cascade },
                   index: true
      t.bigint :author_id, null: false
      t.text   :content,   null: false
      t.jsonb  :mentions,  null: false, default: []   # [{ user_id: 1 }, ...]
      t.timestamps
    end

    add_index :chatwoot_kanban_comments, [:card_id, :created_at]
    add_index :chatwoot_kanban_comments, :author_id
  end
end
