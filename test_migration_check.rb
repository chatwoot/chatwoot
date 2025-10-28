#!/usr/bin/env ruby

# Simple test script to verify migration check functionality
# This simulates the database table existence check

puts "Testing Migration Check Service..."

# Mock the ActiveRecord connection for testing
class MockConnection
  def self.table_exists?(table_name)
    # Simulate missing account_saml_settings table
    table_name == 'account_saml_settings' ? false : true
  end
end

# Mock ActiveRecord for testing
module ActiveRecord
  class Base
    def self.connection
      MockConnection.new
    end
  end
end

# Load the service
require_relative 'app/services/migration_check_service'

# Test the service
if MigrationCheckService.critical_migration_needed?
  puts "✅ Migration check works: Critical migration detected"
  instructions = MigrationCheckService.migration_instructions
  puts "Title: #{instructions[:title]}"
  puts "Message: #{instructions[:message]}"
  puts "Backup Command: #{instructions[:backup_command]}"
  puts "Migrate Command: #{instructions[:migrate_command]}"
  puts "Restart Command: #{instructions[:restart_command]}"
else
  puts "❌ Migration check failed: Should detect critical migration"
  exit 1
end

puts "✅ Test completed successfully!"
