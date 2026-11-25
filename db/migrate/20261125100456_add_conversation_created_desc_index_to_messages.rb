class AddConversationCreatedDescIndexToMessages < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    # Reads a conversation's messages newest first, so finding its latest message stops after the first rows.
    # Chatwoot Cloud already has this index, so the migration skips it there.
    add_index :messages, [:conversation_id, :account_id, :created_at],
              order: { created_at: :desc },
              name: 'index_messages_on_conv_account_created_desc',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
