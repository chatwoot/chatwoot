source "https://rubygems.org"

gem "rake", "~> 13.0"

group :test do
  gem "addressable", "~> 2.3.8", :platforms => %i[jruby ruby_18]
  gem 'coveralls_reborn', '~> 0.19.0', require: false
  gem "json", :platforms => %i[jruby ruby_18 ruby_19]
  gem "mime-types", "~> 1.25", :platforms => %i[jruby ruby_18]
  gem "rack-test"
  gem "rest-client", "~> 1.8.0", :platforms => %i[jruby ruby_18]
  gem "rspec", "~> 3.2"
  gem "rubocop", ">= 0.51", :platforms => %i[ruby_19 ruby_20 ruby_21 ruby_22 ruby_23 ruby_24]
  gem 'simplecov-lcov'
  gem 'tins', '~> 1.13', :platforms => %i[jruby_18 jruby_19 ruby_19]
  gem "webmock", "~> 3.0"
end

# Specify your gem's dependencies in omniauth-oauth2.gemspec
gemspec
