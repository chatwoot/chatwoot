class TestData::DatabaseOptimizer
  class << self
    # Tables that need trigger management
    TABLES_WITH_TRIGGERS = %w[conversations messages].freeze

    # Memory settings in MB
    # Increased work_mem for better query performance with complex operations
    WORK_MEM = 256

    def setup
      Rails.logger.info '==> Setting up database optimizations for improved performance'

      # Remove statement timeout to allow long-running operations to complete
      Rails.logger.info '    Removing statement timeout'
      ActiveRecord::Base.connection.execute('SET statement_timeout = 0')

      # Increase working memory for better query performance
      Rails.logger.info "    Increasing work_mem to #{WORK_MEM}MB"
      ActiveRecord::Base.connection.execute("SET work_mem = '#{WORK_MEM}MB'")

      # Set tables to UNLOGGED mode for better write performance
      # This disables WAL completely for these tables
      Rails.logger.info '    Setting tables to UNLOGGED mode'
      set_tables_unlogged

      # Disable triggers on specified tables to avoid overhead
      Rails.logger.info '    Disabling triggers on specified tables'
      disable_triggers

      Rails.logger.info '==> Database optimizations complete, data generation will run faster'
    end

    def restore
      Rails.logger.info '==> Restoring database settings to normal'

      Rails.logger.info '    Re-enabling triggers on specified tables'
      enable_triggers

      Rails.logger.info '    Setting tables back to LOGGED mode'
      set_tables_logged

      # Reset memory settings to defaults
      Rails.logger.info '    Resetting memory settings to defaults'
      ActiveRecord::Base.connection.execute('RESET work_mem')
      ActiveRecord::Base.connection.execute('RESET maintenance_work_mem')

      Rails.logger.info '==> Database settings restored to normal operation'
    end

    private

    def disable_triggers
      TABLES_WITH_TRIGGERS.each do |table|
        Rails.logger.info "    Disabling triggers on #{table} table"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} DISABLE TRIGGER ALL")
      end
    end

    def enable_triggers
      TABLES_WITH_TRIGGERS.each do |table|
        Rails.logger.info "    Enabling triggers on #{table} table"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} ENABLE TRIGGER ALL")
      end
    end

    def set_tables_unlogged
      TABLES_WITH_TRIGGERS.each do |table|
        Rails.logger.info "    Setting #{table} table as UNLOGGED"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} SET UNLOGGED")
      end
    end

    def set_tables_logged
      TABLES_WITH_TRIGGERS.each do |table|
        Rails.logger.info "    Setting #{table} table as LOGGED"
        ActiveRecord::Base.connection.execute("ALTER TABLE #{table} SET LOGGED")
      end
    end
  end
end
