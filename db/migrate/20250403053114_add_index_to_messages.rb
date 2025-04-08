class AddIndexToMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    setup_environment
    create_composite_index
    create_trigram_index
    remove_old_indexes
    reset_timeout
  end

  def down
    setup_long_timeout
    drop_new_indexes
    restore_original_indexes
    reset_timeout
  end

  private

  def setup_environment
    # First create the trigram extension (needs to be in its own transaction)
    execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
    setup_long_timeout
  end

  def setup_long_timeout
    # Set a very long statement timeout (24 hours)
    execute "SET statement_timeout = '86400000';" # 24 hours in milliseconds
  end

  def reset_timeout
    # Reset statement timeout to default
    execute "SET statement_timeout = '30000';" # 30 seconds
  end

  def create_composite_index
    say_with_time 'Creating composite index for filtering' do
      # Create composite index concurrently
      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_account_inbox_created_at_recent
        ON messages (account_id, inbox_id, created_at DESC)
        WHERE created_at >= '2025-01-01';
      SQL
    end
  end

  def create_trigram_index
    say_with_time 'Creating trigram index' do
      # Create trigram index concurrently
      execute <<-SQL.squish
        CREATE INDEX CONCURRENTLY IF NOT EXISTS
        index_messages_content_trigram_recent
        ON messages USING gin (content gin_trgm_ops)
        WHERE created_at >= '2025-01-01';
      SQL
    end
  end

  def remove_old_indexes
    say_with_time 'Removing old indexes' do
      # Safely remove old indexes concurrently
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_created_at;' if index_exists?(:messages, :created_at)
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_account_id;' if index_exists?(:messages, :account_id)

      if index_exists?(:messages, [:account_id, :created_at, :message_type], name: 'index_messages_on_account_created_type')
        execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_on_account_created_type;'
      end
    end
  end

  def drop_new_indexes
    say_with_time 'Dropping new indexes' do
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_content_trigram_recent;'
      execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_account_inbox_created_at_recent;'
    end
  end

  def restore_original_indexes
    say_with_time 'Restoring original indexes' do
      restore_created_at_index
      restore_account_created_type_index
      restore_account_id_index
    end
  end

  def restore_created_at_index
    execute <<-SQL.squish
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_messages_on_created_at
      ON messages (created_at);
    SQL
  end

  def restore_account_created_type_index
    execute <<-SQL.squish
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_messages_on_account_created_type
      ON messages (account_id, created_at, message_type);
    SQL
  end

  def restore_account_id_index
    execute <<-SQL.squish
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_messages_on_account_id
      ON messages (account_id);
    SQL
  end
end
