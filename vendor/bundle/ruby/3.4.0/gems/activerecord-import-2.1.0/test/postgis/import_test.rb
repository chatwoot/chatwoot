# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/../test_helper")
require File.expand_path("#{File.dirname(__FILE__)}/../support/postgresql/import_examples")

should_support_postgresql_import_functionality

if ActiveRecord::Base.connection.supports_on_duplicate_key_update?
  should_support_postgresql_upsert_functionality
end
