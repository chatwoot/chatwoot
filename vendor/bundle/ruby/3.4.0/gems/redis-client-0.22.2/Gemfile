# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in redis-client.gemspec
gemspec name: "redis-client"

gem "minitest"
gem "rake", "~> 13.2"
gem "rake-compiler"
gem "rubocop"
gem "rubocop-minitest"
gem "toxiproxy"

group :benchmark do
  gem "benchmark-ips"
  gem "hiredis"
  gem "redis", "~> 4.6"
  gem "stackprof", platform: :mri
end

gem "byebug", platform: :mri
