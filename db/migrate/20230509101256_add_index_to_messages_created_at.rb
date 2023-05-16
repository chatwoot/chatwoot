class AddIndexToMessagesCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :messages, [:created_at], name: 'index_messages_on_created_at', algorithm: :concurrently
  end
end
