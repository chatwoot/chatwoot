# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

version = ENV['AR_VERSION'].to_f

mysql2_version = '0.4.0'
mysql2_version = '0.5.0' if version >= 6.1
mysql2_version = '0.5.6' if version >= 8.0
sqlite3_version = '1.3.0'
sqlite3_version = '1.4.0' if version >= 6.0
sqlite3_version = '2.2.0' if version >= 8.0
pg_version = '0.9'
pg_version = '1.1' if version >= 6.1
pg_version = '1.5' if version >= 8.0

group :development, :test do
  gem 'rubocop'
  gem 'rake'
end

# Database Adapters
platforms :ruby do
  gem "mysql2",                 "~> #{mysql2_version}"
  gem "pg",                     "~> #{pg_version}"
  gem "sqlite3",                "~> #{sqlite3_version}"
  # seamless_database_pool requires Ruby ~> 2.0
  gem "seamless_database_pool", "~> 1.0.20" if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0.0')
  gem "trilogy" if version >= 6.0
  if version >= 6.0 && version <= 7.0
    gem "activerecord-trilogy-adapter"
  end
end

platforms :jruby do
  gem "jdbc-mysql"
  gem "jdbc-postgres"
  gem "activerecord-jdbcsqlite3-adapter"
  gem "activerecord-jdbcmysql-adapter"
  gem "activerecord-jdbcpostgresql-adapter"
end

# Support libs
if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.0.0")
  gem "factory_bot"
else
  gem "factory_bot", "~> 5", "< 6.4.5"
end
gem "timecop"
gem "chronic"
gem "mocha", "~> 2.1.0"

# Debugging
platforms :ruby do
  gem "pry-byebug"
  gem "pry", "~> 0.14.0"
end

gem "minitest"

eval_gemfile File.expand_path("../gemfiles/#{version}.gemfile", __FILE__)
