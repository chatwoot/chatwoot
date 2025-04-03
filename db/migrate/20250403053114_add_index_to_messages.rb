class AddIndexToMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # First create the trigram extension (needs to be in its own transaction)
    execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'

    # Set a very long statement timeout (24 hours)
    execute "SET statement_timeout = '86400000';" # 24 hours in milliseconds

    say_with_time 'Creating composite index for filtering' do
      # Create composite index concurrently
      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_account_inbox_created_at_recent
        ON messages (account_id, inbox_id, created_at DESC)
        WHERE created_at >= '2025-01-01';
      SQL
    end

    say_with_time 'Creating trigram index' do
      # Create trigram index concurrently
      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_content_trigram_recent
        ON messages USING gin (content gin_trgm_ops)
        WHERE created_at >= '2025-01-01';
      SQL
    end

    say_with_time 'Removing old indexes' do
      # Safely remove old indexes concurrently
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_created_at;' if index_exists?(:messages, :created_at)
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_account_id;' if index_exists?(:messages, :account_id)

      if index_exists?(:messages, [:account_id, :created_at, :message_type], name: 'index_messages_on_account_created_type')
        execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_account_created_type;'
      end
    end

    # Reset statement timeout to default
    execute "SET statement_timeout = '30000';" # 30 seconds
  end

  def down
    # Set a very long statement timeout (24 hours)
    execute "SET statement_timeout = '86400000';" # 24 hours in milliseconds

    say_with_time 'Dropping new indexes' do
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_content_trigram_recent;'
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_account_inbox_created_at_recent;'
    end

    say_with_time 'Restoring original indexes' do
      # Restore original indexes concurrently
      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_on_created_at
        ON messages (created_at);
      SQL

      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_on_account_created_type
        ON messages (account_id, created_at, message_type);
      SQL

      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_on_account_id
        ON messages (account_id);
      SQL
    end

    # Reset statement timeout to default
    execute "SET statement_timeout = '30000';" # 30 seconds
  end
end
