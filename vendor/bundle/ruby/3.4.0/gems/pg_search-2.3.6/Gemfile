# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'pg', '>= 0.21.0', platform: :ruby
gem "activerecord-jdbcpostgresql-adapter", ">= 1.3.1", platform: :jruby

if ENV['ACTIVE_RECORD_BRANCH']
  gem 'activerecord', git: 'https://github.com/rails/rails.git', branch: ENV['ACTIVE_RECORD_BRANCH']
  gem 'arel', git: 'https://github.com/rails/arel.git' if ENV['ACTIVE_RECORD_BRANCH'] == 'master'
end

gem 'activerecord', ENV['ACTIVE_RECORD_VERSION'] if ENV['ACTIVE_RECORD_VERSION']
