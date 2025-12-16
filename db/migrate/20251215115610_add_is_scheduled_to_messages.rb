class AddIsScheduledToMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :messages, :is_scheduled, :boolean, default: false, null: false
    add_index :messages, [:account_id, :is_scheduled, :created_at], name: 'idx_messages_account_scheduled_created'
  end
end

