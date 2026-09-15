class CreateWhatsappHistorySyncs < ActiveRecord::Migration[7.1]
  def change
    create_syncs_table
    create_events_table
    add_indexes
  end

  private

  def create_syncs_table
    create_table :whatsapp_history_syncs do |t|
      t.bigint :whatsapp_channel_id, null: false
      t.integer :status, null: false, default: 0
      t.integer :progress, null: false, default: 0
      t.integer :imported_messages, null: false, default: 0
      t.integer :imported_conversations, null: false, default: 0
      t.string :request_id
      t.string :last_error_code
      t.text :last_error_message
      t.datetime :started_at
      t.datetime :first_event_at
      t.datetime :completed_at
      t.timestamps
    end
  end

  def create_events_table
    create_table :whatsapp_history_sync_events do |t|
      t.bigint :whatsapp_history_sync_id, null: false
      t.string :event_key, null: false
      t.integer :status, null: false, default: 0
      t.integer :phase
      t.integer :chunk_order
      t.integer :progress
      t.jsonb :payload, null: false, default: {}
      t.text :error_message
      t.datetime :processed_at
      t.timestamps
    end
  end

  def add_indexes
    add_index :whatsapp_history_syncs, :whatsapp_channel_id, unique: true
    add_index :whatsapp_history_syncs, :request_id
    add_index :whatsapp_history_sync_events,
              [:whatsapp_history_sync_id, :event_key],
              unique: true,
              name: 'idx_whatsapp_history_events_on_sync_and_key'
    add_index :whatsapp_history_sync_events,
              [:whatsapp_history_sync_id, :status],
              name: 'idx_whatsapp_history_events_on_sync_and_status'
  end
end
