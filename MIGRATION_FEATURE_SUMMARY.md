# Migration Notice Feature Implementation

## Overview
This feature adds a critical migration check for users upgrading from v4.6.0 to v4.7.0 who might encounter login issues due to missing `account_saml_settings` table.

## Files Created/Modified

### 1. MigrationCheckService (`app/services/migration_check_service.rb`)
- Checks if the critical `account_saml_settings` table exists
- Detects if migrations are needed based on migration version
- Returns detailed instructions for database backup and migration

### 2. Sessions Controller Enhancement (`app/controllers/devise_overrides/sessions_controller.rb`)
- Added migration check in the `create` method before authentication
- Returns detailed JSON response with migration instructions when needed
- Includes backup, migrate, and restart commands for Docker users

### 3. Internationalization Support
- Added migration messages to English locale file
- Supports I18n for multiple languages
- Provides clear instructions for users

## How It Works

1. **Login Attempt**: When a user tries to log in, the system checks for critical migrations
2. **Migration Detection**: If `account_saml_settings` table is missing and migration version indicates it should exist, users get a helpful error message
3. **User Guidance**: Instead of a generic error, users receive:
   - Clear explanation of the issue
   - Backup command for Docker: `docker exec chatwoot-db pg_dump -U postgres chatwoot_production > backup_before_migrate_$(date +%F).sql`
   - Migration command: `docker exec -it chatwoot-rails bundle exec rails db:migrate`
   - Restart command: `docker restart chatwoot-rails`

## Benefits
- **Prevents Login Failures**: Users understand why login fails during upgrades
- **Reduces Support Tickets**: Clear instructions reduce support burden
- **Safe Upgrades**: Encourages database backup before migration
- **Multi-language Support**: Uses I18n for international users

## Technical Details

### Migration Check Logic
```ruby
def self.critical_migration_needed?
  return false if migration_completed?

  table_missing = !table_exists?('account_saml_settings')
  version_check = current_migration_version >= SAML_SETTINGS_MIGRATION_VERSION

  table_missing && version_check
end
```

### Response Format
```json
{
  "error": "migration_required",
  "migration_warning": true,
  "title": "Database Migration Required",
  "message": "You are upgrading to a newer version that requires database migrations to be run before login.",
  "details": "The missing account_saml_settings table will prevent users from logging in. Please backup your database and run migrations before proceeding.",
  "backup_command": "docker exec chatwoot-db pg_dump -U postgres chatwoot_production > backup_before_migrate_$(date +%F).sql",
  "migrate_command": "docker exec -it chatwoot-rails bundle exec rails db:migrate",
  "restart_command": "docker restart chatwoot-rails"
}
```

## Testing
To test this feature:
1. Create a database without the `account_saml_settings` table
2. Attempt to log in - should receive migration warning
3. Run migrations - should resolve the issue
4. Attempt to log in again - should work normally

## Future Enhancements
- Add support for other critical migrations beyond just `account_saml_settings`
- Create a dedicated admin page for migration status
- Add email notifications for administrators when migrations are needed
- Include version-specific migration instructions
