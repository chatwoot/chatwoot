# frozen_string_literal: true

# Service to check for critical migration issues that might prevent login
class MigrationCheckService
  # This migration creates the account_saml_settings table
  # Users upgrading from v4.6.0 to v4.7.0 without running migrations
  # will encounter login issues due to missing this table
  SAML_SETTINGS_MIGRATION_VERSION = 20_250_825_070_005

  def self.critical_migration_needed?
    return false if migration_completed?

    # Check if the table that causes the login issue exists
    table_missing = !table_exists?('account_saml_settings')

    # Only consider it critical if we're past the version that introduced this table
    version_check = current_migration_version >= SAML_SETTINGS_MIGRATION_VERSION

    table_missing && version_check
  end

  def self.migration_instructions
    {
      title: I18n.t('migration_check.critical.title', default: 'Database Migration Required'),
      message: I18n.t('migration_check.critical.message',
                      default: 'You are upgrading to a newer version that requires database migrations to be run.'),
      backup_command: I18n.t('migration_check.critical.backup_command',
                            default: 'docker exec chatwoot-db pg_dump -U postgres chatwoot_production > backup_before_migrate_$(date +%F).sql'),
      migrate_command: I18n.t('migration_check.critical.migrate_command',
                            default: 'docker exec -it chatwoot-rails bundle exec rails db:migrate'),
      restart_command: I18n.t('migration_check.critical.restart_command',
                            default: 'docker restart chatwoot-rails'),
      details: I18n.t('migration_check.critical.details',
                     default: 'The missing account_saml_settings table will prevent users from logging in. Please backup your database and run migrations before proceeding.')
    }
  end

  private

  def self.migration_completed?
    ActiveRecord::Base.connection.table_exists?('schema_migrations') &&
      ActiveRecord::Base.connection.execute(
        "SELECT 1 FROM schema_migrations WHERE version = '#{SAML_SETTINGS_MIGRATION_VERSION}'"
      ).any?
  end

  def self.table_exists?(table_name)
    ActiveRecord::Base.connection.table_exists?(table_name)
  end

  def self.current_migration_version
    # Get the highest migration version that should have been run
    # This is a simplified approach - in practice, you might want to check
    # against the latest migration in the db/migrate directory
    migration_files = Dir[Rails.root.join('db', 'migrate', '*.rb')]
    return 0 if migration_files.empty?

    migration_files.map { |f| File.basename(f, '.rb').split('_').first.to_i }.max || 0
  end
end
