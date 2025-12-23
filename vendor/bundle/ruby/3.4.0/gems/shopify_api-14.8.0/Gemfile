# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :test, :development do
  gem "pry-byebug"
end

group :development do
  gem "rake"
  gem "rubocop"
  gem "rubocop-shopify"
  gem "rubocop-sorbet"
  gem "sorbet"
  gem "tapioca"
end

group :test do
  gem "minitest"
  gem "fakefs", require: false
  gem "webmock"
  gem "mocha"
end
