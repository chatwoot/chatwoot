class AddIndexForMessageTypeAccountDate < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :messages, [:account_id, :created_at, :message_type], name: 'index_messages_on_account_created_type', algorithm: :concurrently
  end
end
