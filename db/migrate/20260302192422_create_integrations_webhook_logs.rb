class CreateIntegrationsWebhookLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :integrations_webhook_logs do |t|
      t.bigint :hook_id, null: false
      t.string :event_type, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :payload, default: {}
      t.jsonb :response_data, default: {}
      t.text :error_message
      t.datetime :processed_at

      t.timestamps
    end

    add_index :integrations_webhook_logs, :hook_id
    add_index :integrations_webhook_logs, :status
    add_index :integrations_webhook_logs, :created_at
    add_index :integrations_webhook_logs, %i[hook_id created_at]
    add_foreign_key :integrations_webhook_logs, :integrations_hooks, column: :hook_id
  end
end
