class AddConversationCreatedIndexToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Serves per-conversation message lookups ordered by created_at (message pagination,
    # last message in conversation lists), which otherwise fall back to a backward scan
    # of the global created_at index.
    add_index :messages, [:conversation_id, :created_at],
              name: 'index_messages_on_conversation_id_and_created_at',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
