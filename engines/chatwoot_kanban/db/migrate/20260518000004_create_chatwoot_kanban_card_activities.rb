class CreateChatwootKanbanCardActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_kanban_card_activities do |t|
      t.references :card, null: false,
                   foreign_key: { to_table: :chatwoot_kanban_cards, on_delete: :cascade },
                   index: true
      t.bigint :actor_id
      t.string :action,  null: false, limit: 40
      t.jsonb  :payload, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :chatwoot_kanban_card_activities, [:card_id, :created_at]
    add_index :chatwoot_kanban_card_activities, :actor_id
  end
end
