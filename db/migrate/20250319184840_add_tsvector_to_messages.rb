class AddTsvectorToMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    set_statement_timeout
    add_tsvector_column
    update_messages_with_tsvector
    add_not_null_constraint
    set_default_value
    create_gin_index
    create_supporting_index
    create_update_trigger
    reset_statement_timeout
    say 'Migration completed successfully'
  end

  def down
    say_with_time 'Removing tsvector column and related objects' do
      execute 'DROP TRIGGER IF EXISTS messages_content_update_trigger ON messages;'
      execute 'DROP FUNCTION IF EXISTS messages_content_trigger();'
      execute 'DROP INDEX IF EXISTS index_messages_on_content_tsvector;'
      remove_column :messages, :content_tsvector if column_exists?(:messages, :content_tsvector)
    end
    say 'Rollback completed successfully'
  end

  private

  def set_statement_timeout
    execute 'SET statement_timeout = 36000000;' # 10 hours in milliseconds
  end

  def add_tsvector_column
    return if column_exists?(:messages, :content_tsvector)

    add_column :messages, :content_tsvector, :tsvector, null: true
  end

  def update_messages_with_tsvector
    say_with_time 'Updating messages with tsvector in batches (last 3 months)' do
      batch_size = 10_000
      total_count = 0

      messages_to_update.find_in_batches(batch_size: batch_size) do |batch|
        process_message_batch(batch, total_count)
        total_count += batch.size
      end

      say "Finished processing all batches. Total messages processed: #{total_count}"
    end
  end

  def messages_to_update
    Message.where(content_tsvector: nil)
           .where("created_at >= NOW() - INTERVAL '3 months'")
  end

  def process_message_batch(batch, total_count)
    batch_count = batch.size
    say "Processing batch of #{batch_count} messages (total processed: #{total_count + batch_count})"

    # Perform a single bulk update using a single SQL query
    ids = batch.pluck(:id)
    return if ids.empty?

    execute <<-SQL.squish
      UPDATE messages
      SET content_tsvector = to_tsvector('english', coalesce(content, ''))
      WHERE id IN (#{ids.join(',')}) AND content_tsvector IS NULL;
    SQL
  end

  def add_not_null_constraint
    say_with_time 'Adding NOT NULL constraint to content_tsvector' do
      change_column_null :messages, :content_tsvector, false
    end
  end

  def set_default_value
    say_with_time 'Setting default value for content_tsvector' do
      execute <<-SQL.squish
        ALTER TABLE messages ALTER COLUMN content_tsvector SET DEFAULT to_tsvector('english', '');
      SQL
    end
  end

  def create_gin_index
    say_with_time 'Creating GIN index on content_tsvector if not exists' do
      # Check if index exists
      index_exists = connection.select_value(
        "SELECT 1 FROM pg_indexes WHERE indexname = 'index_messages_on_content_tsvector'"
      ).present?

      # Create index only if it doesn't exist
      if index_exists
        say 'GIN index on content_tsvector already exists'
      else
        say 'Creating GIN index on content_tsvector'
        execute 'CREATE INDEX CONCURRENTLY index_messages_on_content_tsvector ON messages USING GIN (content_tsvector);'
      end
    end
  end

  def create_supporting_index
    say_with_time 'Creating index on inbox_id and created_at' do
      # Check if index exists
      index_exists = connection.select_value(
        "SELECT 1 FROM pg_indexes WHERE indexname = 'index_messages_inbox_created_at'"
      ).present?

      # Create index only if it doesn't exist
      if index_exists
        say 'Index on inbox_id and created_at already exists'
      else
        say 'Creating index on inbox_id and created_at'
        execute 'CREATE INDEX CONCURRENTLY index_messages_inbox_created_at ON messages (inbox_id, created_at DESC);'
      end
    end
  end

  def create_update_trigger
    say_with_time 'Creating trigger for automatic tsvector updates' do
      execute <<-SQL.squish
        CREATE OR REPLACE FUNCTION messages_content_trigger() RETURNS trigger AS $$
        BEGIN
          NEW.content_tsvector := to_tsvector('english', coalesce(NEW.content, ''));
          RETURN NEW;
        END;
        $$ LANGUAGE plpgsql;
      SQL

      trigger_exists = connection.select_value(
        "SELECT 1 FROM pg_trigger WHERE tgname = 'messages_content_update_trigger'"
      ).present?

      if trigger_exists
        say 'Trigger for automatic tsvector updates already exists'
      else
        execute <<-SQL.squish
          CREATE TRIGGER messages_content_update_trigger
          BEFORE INSERT OR UPDATE OF content ON messages
          FOR EACH ROW
          EXECUTE FUNCTION messages_content_trigger();
        SQL
        say 'Created trigger for automatic tsvector updates'
      end
    end
  end

  def reset_statement_timeout
    execute 'RESET statement_timeout;'
  end
end
