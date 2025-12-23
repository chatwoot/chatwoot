# frozen_string_literal: true

source "https://rubygems.org"
ruby RUBY_VERSION

gem "rake"

# Ruby 3.0 does not ship it anymore.
# TODO: We should probably refactor specs to avoid need for it.
gem "webrick"

group :development do
  gem "guard-rspec", :require => false
  gem "nokogiri",    :require => false
  gem "pry",         :require => false

  # RSpec formatter
  gem "fuubar", :require => false

  platform :mri do
    gem "pry-byebug"
  end
end

group :test do
  gem "certificate_authority", "~> 1.0", :require => false

  gem "backports"

  gem "rubocop", "~> 1.30.0"
  gem "rubocop-performance"
  gem "rubocop-rake"
  gem "rubocop-rspec"

  gem "simplecov",      :require => false
  gem "simplecov-lcov", :require => false

  gem "rspec", "~> 3.10"
  gem "rspec-its"

  gem "yardstick"
end

group :doc do
  gem "kramdown"
  gem "yard"
end

# Specify your gem's dependencies in http.gemspec
gemspec
