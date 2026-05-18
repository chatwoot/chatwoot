class CreateChatwootGlpiTicketLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :chatwoot_glpi_ticket_links do |t|
      t.references :account, null: false,
                   foreign_key: { to_table: :accounts, on_delete: :cascade },
                   index: true
      t.bigint  :conversation_id
      t.bigint  :kanban_card_id
      t.integer :glpi_ticket_id, null: false
      t.string  :sync_direction, null: false, default: 'both'   # both | inbound | outbound
      t.string  :last_status                                     # cached GLPI status name
      t.datetime :last_synced_at
      t.timestamps
    end

    add_index :chatwoot_glpi_ticket_links, [:account_id, :glpi_ticket_id], unique: true
    add_index :chatwoot_glpi_ticket_links, :conversation_id
    add_index :chatwoot_glpi_ticket_links, :kanban_card_id
  end
end
