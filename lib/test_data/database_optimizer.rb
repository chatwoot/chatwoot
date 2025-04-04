class TestData::DatabaseOptimizer
  class << self
    def setup
      Rails.logger.info '==> Setting up database optimizations for improved performance'

      # Disable ActiveRecord logging to reduce console output during data generation
      Rails.logger.info '    Disabling ActiveRecord logging'
      ActiveRecord::Base.logger = nil

      # Remove statement timeout to allow long-running operations to complete
      Rails.logger.info '    Removing statement timeout'
      ActiveRecord::Base.connection.execute('SET statement_timeout = 0')

      # Disable synchronous commits to improve write performance
      # This makes PostgreSQL return success before writing to disk, improving throughput
      Rails.logger.info '    Disabling synchronous commits for better write performance'
      ActiveRecord::Base.connection.execute('SET synchronous_commit = off')

      # Disable triggers on conversation and message tables to avoid overhead
      # This prevents firing of triggers that might slow down bulk inserts
      Rails.logger.info '    Disabling triggers on conversations and messages tables'
      ActiveRecord::Base.connection.execute('ALTER TABLE conversations DISABLE TRIGGER ALL')
      ActiveRecord::Base.connection.execute('ALTER TABLE messages DISABLE TRIGGER ALL')

      Rails.logger.info '==> Database optimizations complete, data generation will run faster'
    end

    def restore
      Rails.logger.info '==> Restoring database settings to normal'

      Rails.logger.info '    Re-enabling synchronous commits'
      ActiveRecord::Base.connection.execute('SET synchronous_commit = on')

      Rails.logger.info '    Re-enabling triggers on conversations and messages tables'
      ActiveRecord::Base.connection.execute('ALTER TABLE conversations ENABLE TRIGGER ALL')
      ActiveRecord::Base.connection.execute('ALTER TABLE messages ENABLE TRIGGER ALL')

      Rails.logger.info '==> Database settings restored to normal operation'
    end
  end
end
