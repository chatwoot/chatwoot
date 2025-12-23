# frozen_string_literal: true

require 'warning'
# Ignore Ruby 2.7 warnings from Active Record
Warning.ignore :keyword_separation

# https://github.com/grodowski/undercover#setting-up-required-lcov-reporting
require 'simplecov'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
SimpleCov.start do
  add_filter(%r{^/spec/})
  enable_coverage(:branch)
end
require 'undercover'

require "bundler/setup"
require "pg_search"

RSpec.configure do |config|
  config.expect_with :rspec do |expects|
    expects.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = 'tmp/examples.txt'
end

require 'support/database'
require 'support/with_model'

DOCUMENTS_SCHEMA = lambda do |t|
  t.belongs_to :searchable, polymorphic: true, index: true
  t.text :content
  t.timestamps null: false

  # Used to test additional_attributes setup
  t.text :additional_attribute_column
end
