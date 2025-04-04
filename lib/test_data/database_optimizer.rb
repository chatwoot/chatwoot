module TestData
  class DatabaseOptimizer
    class << self
      def setup
        puts '==> Setting up database optimizations'
        ActiveRecord::Base.logger = nil
        ActiveRecord::Base.connection.execute('SET statement_timeout = 0')
        ActiveRecord::Base.connection.execute('SET synchronous_commit = off')
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
