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
    # A previous failed CONCURRENTLY build may have left an invalid index stub.
    # Drop it so the build below does not silently skip over a broken index.
    drop_invalid_index_if_present

    # CREATE INDEX CONCURRENTLY on a large table can take minutes; disable the
    # session statement_timeout so the build is not cancelled mid-run.
    execute 'SET statement_timeout TO 0'
    add_index :messages, [:conversation_id, :created_at],
              name: 'index_messages_on_conversation_id_and_created_at',
              algorithm: :concurrently, if_not_exists: true
  ensure
    execute 'RESET statement_timeout'
  end

  def down
    execute 'SET statement_timeout TO 0'
    remove_index :messages, name: 'index_messages_on_conversation_id_and_created_at',
                            algorithm: :concurrently, if_exists: true
  ensure
    execute 'RESET statement_timeout'
  end

  private

  INDEX_NAME = 'index_messages_on_conversation_id_and_created_at'.freeze

  def drop_invalid_index_if_present
    result = execute(<<~SQL.squish)
      SELECT indisvalid
      FROM pg_class
      JOIN pg_index ON pg_index.indexrelid = pg_class.oid
      WHERE pg_class.relname = '#{INDEX_NAME}'
    SQL
    return if result.none? || result.first['indisvalid'] == 't'

    execute 'SET statement_timeout TO 0'
    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently
  ensure
    execute 'RESET statement_timeout'
  end
end
