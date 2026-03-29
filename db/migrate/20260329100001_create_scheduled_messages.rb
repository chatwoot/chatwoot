class CreateScheduledMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :scheduled_messages do |t|
      t.bigint :account_id, null: false
      t.bigint :scheduler_id, null: false
      t.bigint :contact_id
      t.string :external_id, null: false
      t.string :customer_phone, null: false
      t.string :customer_name
      t.string :message_type, null: false
      t.datetime :scheduled_at, null: false
      t.string :status, default: 'pending', null: false
      t.datetime :sent_at
      t.string :whatsapp_message_id
      t.string :error_message
      t.jsonb :template_params, default: {}
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :scheduled_messages, [:external_id, :message_type], unique: true, name: 'idx_scheduled_messages_unique'
    add_index :scheduled_messages, [:account_id, :status, :scheduled_at], name: 'idx_scheduled_messages_dispatch'
    add_index :scheduled_messages, :scheduler_id
    add_index :scheduled_messages, :contact_id
    add_index :scheduled_messages, :account_id
  end
end
