source 'https://rubygems.org'
gemspec

gem 'rake'
gem 'mongrel',  '1.2.0.pre2'
gem 'json'

group :development do
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
end

group :test do
  gem 'rexml'
  gem 'rspec',    '~> 3.4'
  gem 'simplecov', require: false
  gem 'aruba'
  gem 'cucumber', '~> 2.3'
  gem 'webmock'
  gem 'addressable'
end

group :development, :test do
  gem 'pry'
end
