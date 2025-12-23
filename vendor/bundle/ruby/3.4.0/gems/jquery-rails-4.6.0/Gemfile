source 'https://rubygems.org'

gem "mime-types", "< 3", group: :test

if RUBY_VERSION >= '2.2.2'
  gem 'rails'
  gem 'rack'
  gem 'json', '>= 2'
else
  gem 'rails', '~> 4.2.0'
  gem 'rack', '~>1.6'
  gem 'json', '~> 1.8.0'
end

if RUBY_VERSION >= '2.1'
  gem 'nokogiri'
else
  gem 'nokogiri', '~> 1.6.0'
end

# Specify your gem's dependencies in jquery-rails.gemspec
gemspec
