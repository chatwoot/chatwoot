class CreateChatwootKanbanLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_labels do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts, on_delete: :cascade }, index: true
      t.string :name,  null: false, limit: 60
      t.string :color, null: false, limit: 16, default: '#6b7280'
      t.timestamps
    end
    add_index :chatwoot_kanban_labels, [:account_id, :name], unique: true

    create_table :chatwoot_kanban_card_labels do |t|
      t.references :card,  null: false,
                   foreign_key: { to_table: :chatwoot_kanban_cards,  on_delete: :cascade },
                   index: true
      t.references :label, null: false,
                   foreign_key: { to_table: :chatwoot_kanban_labels, on_delete: :cascade },
                   index: true
      t.timestamps
    end
    add_index :chatwoot_kanban_card_labels, [:card_id, :label_id], unique: true
  end
end
