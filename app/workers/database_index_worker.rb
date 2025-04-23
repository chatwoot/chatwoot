class DatabaseIndexWorker
  include Sidekiq::Worker
  sidekiq_options queue: :async_database_migration,
                  retry: 3,
                  timeout: 86_400 # 24 hours – allows long‑running index operations

  def perform(action = 'create')
    case action
    when 'create'
      create_indexes
    when 'drop'
      drop_indexes
    end
  end

  private

  def create_indexes
    setup_environment
    create_composite_index
    create_trigram_index
    reset_timeout
  end

  def drop_indexes
    setup_long_timeout
    drop_new_indexes
    reset_timeout
  end

  def setup_environment
    # First create the trigram extension (needs to be in its own transaction)
    ActiveRecord::Base.connection.execute 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
    setup_long_timeout
  end

  def setup_long_timeout
    # Set a very long statement timeout (24 hours) for this connection only
    ActiveRecord::Base.connection.execute "SET statement_timeout = '86400000';" # 24 hours in milliseconds
  end

  def reset_timeout
    # Reset statement timeout to default for this connection
    ActiveRecord::Base.connection.execute "SET statement_timeout = '#{ENV.fetch('POSTGRES_STATEMENT_TIMEOUT', '14s')}';" # Reset to default
  end

  def create_composite_index
    ActiveRecord::Base.connection.execute <<-SQL.squish
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_messages_account_inbox_created_at
      ON messages (account_id, inbox_id, created_at DESC);
    SQL
  end

  def create_trigram_index
    ActiveRecord::Base.connection.execute <<-SQL.squish
      CREATE INDEX CONCURRENTLY IF NOT EXISTS
      index_messages_content_trigram
      ON messages USING gin (content gin_trgm_ops);
    SQL
  end

  def drop_new_indexes
    ActiveRecord::Base.connection.execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_content_trigram;'
    ActiveRecord::Base.connection.execute 'DROP INDEX CONCURRENTLY IF EXISTS index_messages_account_inbox_created_at;'
  end
end
