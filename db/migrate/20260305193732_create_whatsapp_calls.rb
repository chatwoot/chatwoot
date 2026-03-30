class CreateWhatsappCalls < ActiveRecord::Migration[7.1]
  def change
    create_table :whatsapp_calls do |t|
      t.bigint  :account_id,          null: false
      t.bigint  :inbox_id,            null: false
      t.bigint  :conversation_id,     null: false
      t.bigint  :accepted_by_agent_id
      t.string  :call_id,             null: false
      t.string  :direction,           null: false
      t.string  :status,              null: false, default: 'ringing'
      t.integer :duration_seconds
      t.string  :end_reason
      t.jsonb   :meta,                null: false, default: {}
      t.timestamps
    end

    add_index :whatsapp_calls, :call_id, unique: true
    add_index :whatsapp_calls, [:account_id, :conversation_id]
    add_index :whatsapp_calls, [:inbox_id, :status]
  end
end
