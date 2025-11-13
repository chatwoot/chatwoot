# frozen_string_literal: true

class CreateScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_messages do |t|
      # References
      t.references :account, null: false, foreign_key: true, index: true
      t.references :conversation, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.references :sender, foreign_key: { to_table: :users }, index: true
      t.references :message, foreign_key: true, index: true

      # Message Content
      t.text :content, null: false
      t.integer :message_type, null: false, default: 1  # outgoing
      t.integer :content_type, null: false, default: 0  # text
      t.json :content_attributes, default: {}
      t.jsonb :additional_attributes, default: {}
      t.boolean :private, default: false, null: false

      # Scheduling
      t.datetime :scheduled_at, null: false
      t.datetime :sent_at
      t.datetime :cancelled_at

      # Status & Error Handling
      t.integer :status, null: false, default: 0  # pending: 0, sent: 1, failed: 2, cancelled: 3
      t.text :error_message

      t.timestamps
    end

    # Índices para performance
    add_index :scheduled_messages, [:account_id, :status]
    add_index :scheduled_messages, [:scheduled_at, :status]
    add_index :scheduled_messages, [:conversation_id, :status]
  end
end
