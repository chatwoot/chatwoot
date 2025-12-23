# frozen_string_literal: true

require 'pathname'
require 'rake'
require 'logger'

test_dir = Pathname.new File.dirname(__FILE__)
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require "fileutils"

ENV["RAILS_ENV"] = "test"

require "bundler"
Bundler.setup

unless RbConfig::CONFIG["RUBY_INSTALL_NAME"] =~ /jruby/
  require 'pry'
  require 'pry-byebug'
end

require "active_record"
require "active_record/fixtures"
require "active_support/test_case"
require 'active_support/testing/autorun'
require "mocha/minitest"

require 'timecop'
require 'chronic'

begin
  require 'composite_primary_keys'
rescue LoadError
  if ENV['AR_VERSION'].to_f <= 7.1
    ENV['SKIP_COMPOSITE_PK'] = 'true'
  end
end

adapter = ENV["ARE_DB"] || "sqlite3"

FileUtils.mkdir_p 'log'
ActiveRecord::Base.logger = Logger.new("log/test.log")
ActiveRecord::Base.logger.level = Logger::DEBUG

if ActiveRecord.respond_to?(:use_yaml_unsafe_load)
  ActiveRecord.use_yaml_unsafe_load = true
elsif ActiveRecord::Base.respond_to?(:use_yaml_unsafe_load)
  ActiveRecord::Base.use_yaml_unsafe_load = true
end

if ENV['AR_VERSION'].to_f >= 6.0
  yaml_config = if Gem::Version.new(Psych::VERSION) >= Gem::Version.new('3.2.1')
    YAML.safe_load_file(test_dir.join("database.yml"), aliases: true)[adapter]
  else
    YAML.load_file(test_dir.join("database.yml"))[adapter]
  end
  config = ActiveRecord::DatabaseConfigurations::HashConfig.new("test", adapter, yaml_config)
  ActiveRecord::Base.configurations.configurations << config
else
  ActiveRecord::Base.configurations["test"] = YAML.load_file(test_dir.join("database.yml"))[adapter]
end

if ActiveRecord.respond_to?(:default_timezone)
  ActiveRecord.default_timezone = :utc
else
  ActiveRecord::Base.default_timezone = :utc
end

require "activerecord-import"
ActiveRecord::Base.establish_connection :test

ActiveSupport::Notifications.subscribe(/active_record.sql/) do |_, _, _, _, hsh|
  ActiveRecord::Base.logger.info hsh[:sql]
end

require "factory_bot"
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |file| require file }

# Load base/generic schema
require test_dir.join("schema/version")
require test_dir.join("schema/generic_schema")
adapter_schema = test_dir.join("schema/#{adapter}_schema.rb")
require adapter_schema if File.exist?(adapter_schema)

Dir["#{File.dirname(__FILE__)}/models/*.rb"].sort.each { |file| require file }

# Prevent this deprecation warning from breaking the tests.
Rake::FileList.send(:remove_method, :import)

ActiveSupport::TestCase.test_order = :random
