class IndexConversationsByNewestMessage < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :conversations, %i[account_id last_message_at display_id],
              order: { last_message_at: 'DESC NULLS LAST', display_id: :desc },
              name: 'index_conversations_on_account_newest_message', algorithm: :concurrently
  end
end
