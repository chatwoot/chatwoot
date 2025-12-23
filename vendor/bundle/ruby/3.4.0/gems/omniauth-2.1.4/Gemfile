source 'https://rubygems.org'

gem 'jruby-openssl', '~> 0.10.5', platforms: :jruby
gem 'rake', '>= 12.0'
gem 'yard', '>= 0.9.11'

group :development do
  gem 'benchmark-ips'
  gem 'kramdown'
  gem 'memory_profiler'
  gem 'pry'
end

group :test do
  gem 'cgi'
  gem 'coveralls_reborn', '~> 0.19.0', require: false
  gem 'rack-test'
  gem 'rspec', '~> 3.5'
  gem 'rack-freeze'
  gem 'rubocop', '>= 0.58.2', '< 0.69.0', platforms: %i[ruby_22 ruby_23 ruby_24]
  gem 'simplecov-lcov'
end

gemspec
