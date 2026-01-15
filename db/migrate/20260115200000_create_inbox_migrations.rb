# frozen_string_literal: true

class CreateInboxMigrations < ActiveRecord::Migration[7.0]
  def change
    create_table :inbox_migrations do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :source_inbox, null: false, foreign_key: { to_table: :inboxes }, index: true
      t.references :destination_inbox, null: false, foreign_key: { to_table: :inboxes }, index: true
      t.references :user, foreign_key: true, index: true # who initiated the migration

      # Status tracking
      t.integer :status, null: false, default: 0 # enum: queued, running, completed, failed, cancelled

      # Progress counters
      t.integer :conversations_count, default: 0
      t.integer :conversations_moved, default: 0
      t.integer :messages_count, default: 0
      t.integer :messages_moved, default: 0
      t.integer :attachments_count, default: 0
      t.integer :attachments_moved, default: 0
      t.integer :contact_inboxes_count, default: 0
      t.integer :contact_inboxes_moved, default: 0
      t.integer :contacts_merged, default: 0

      # Error tracking
      t.text :error_message
      t.text :error_backtrace

      # Timing
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    # Prevent multiple concurrent migrations from same source inbox
    add_index :inbox_migrations, [:source_inbox_id, :status],
              where: 'status IN (0, 1)', # queued or running
              name: 'index_inbox_migrations_active_source'
  end
end
