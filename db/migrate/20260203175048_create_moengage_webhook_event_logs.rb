class CreateMoengageWebhookEventLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :moengage_webhook_event_logs do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :hook, null: false, foreign_key: { to_table: :integrations_hooks }, index: true
      t.string :event_name
      t.integer :status, default: 0, null: false
      t.jsonb :payload, default: {}
      t.jsonb :response_data, default: {}
      t.text :error_message
      t.references :contact, foreign_key: true, index: true
      t.references :conversation, foreign_key: true, index: true
      t.integer :processing_time_ms

      t.timestamps
    end

    add_index :moengage_webhook_event_logs, [:account_id, :created_at]
    add_index :moengage_webhook_event_logs, [:hook_id, :created_at]
    add_index :moengage_webhook_event_logs, [:status, :created_at]
  end
end
