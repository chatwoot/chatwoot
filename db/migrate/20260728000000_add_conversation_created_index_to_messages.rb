class AddConversationCreatedIndexToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # Message pagination (MessageFinder#messages_before) and the per-conversation
  # last-message lookup in api/v1/conversations/partials/_conversation.json.jbuilder
  # both filter by conversation_id and order by created_at, but no index covers
  # that shape. For old/inactive conversations Postgres falls back to an
  # Index Scan Backward on the global index_messages_on_created_at, which on a
  # large messages table crosses statement_timeout (default 14s) and 500s. The
  # existing index_messages_on_conversation_account_type_created can't serve the
  # ORDER BY because account_id / message_type sit between the two columns.
  def up
    add_index :messages, [:conversation_id, :created_at],
              name: 'index_messages_on_conversation_id_and_created_at',
              algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :messages, name: 'index_messages_on_conversation_id_and_created_at',
                            algorithm: :concurrently, if_exists: true
  end
end
