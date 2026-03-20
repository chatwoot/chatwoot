class AddConversationTypeToConversations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_column :conversations, :conversation_type, :integer, default: 0, null: false
    add_index :conversations, [:account_id, :conversation_type], algorithm: :concurrently
    add_index :conversations, [:inbox_id, :conversation_type], algorithm: :concurrently
  end
end
