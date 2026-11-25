class IndexConversationsByLastMessage < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :conversations, %i[account_id last_message_at display_id],
              name: 'index_conversations_on_account_oldest_message', algorithm: :concurrently
  end
end
