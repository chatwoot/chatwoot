module TestData
  class DatabaseOptimizer
    class << self
      def setup
        puts '==> Setting up database optimizations'
        # Disable ActiveRecord logging to reduce console output during data generation
        ActiveRecord::Base.logger = nil
        # Remove statement timeout to allow long-running operations to complete
        ActiveRecord::Base.connection.execute('SET statement_timeout = 0')
        # Disable synchronous commits to improve write performance
        # This makes PostgreSQL return success before writing to disk, improving throughput
        ActiveRecord::Base.connection.execute('SET synchronous_commit = off')

        # Disable triggers on conversation and message tables to avoid overhead
        # This prevents firing of triggers that might slow down bulk inserts
        ActiveRecord::Base.connection.execute('ALTER TABLE conversations DISABLE TRIGGER ALL')
        ActiveRecord::Base.connection.execute('ALTER TABLE messages DISABLE TRIGGER ALL')
      end

      def restore
        puts '==> Restoring database settings'
        ActiveRecord::Base.connection.execute('SET synchronous_commit = on')
        ActiveRecord::Base.connection.execute('ALTER TABLE conversations ENABLE TRIGGER ALL')
        ActiveRecord::Base.connection.execute('ALTER TABLE messages ENABLE TRIGGER ALL')
      end
    end
  end
end
