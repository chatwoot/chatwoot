# frozen_string_literal: true
source 'http://rubygems.org'

gemspec

if ENV.key?('CONCURRENCY')
  case ENV['CONCURRENCY']
  when 'async-websocket'
    gem 'async-websocket', '~> 0.8.0', require: false
  else
    gem ENV['CONCURRENCY'], require: false
  end
end

group :test do
  gem 'activesupport'
  gem 'base64'
  gem 'bigdecimal'
  gem 'erubis'
  gem 'faraday-typhoeus'
  gem 'json-schema'
  gem 'mutex_m'
  gem 'racc'
  gem 'rake', '~> 13'
  gem 'rspec'
  gem 'rubocop', '1.26.1' # Lock to specific version to avoid breaking cops/changes
  gem 'rubocop-performance'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'simplecov'
  gem 'simplecov-lcov'
  gem 'timecop'
  gem 'vcr'
  gem 'webmock'
end
