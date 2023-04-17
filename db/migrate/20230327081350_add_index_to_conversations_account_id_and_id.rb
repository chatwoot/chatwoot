class AddIndexToConversationsAccountIdAndId < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :conversations, [:account_id, :id], name: 'index_conversations_on_id_and_account_id', algorithm: :concurrently
  end
end
