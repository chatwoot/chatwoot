# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development do
  # bootstrapping
  gem "bundler", "~> 2.3"
  gem "rake", "13.2.1"

  # building extensions
  gem "rake-compiler", "1.2.8"
  gem "rake-compiler-dock", "1.7.0"

  # parser generator
  gem "rexical", "1.0.8"

  # tests
  gem "minitest", "5.25.4"
  gem "minitest-parallel_fork", "2.0.0"
  gem "ruby_memcheck", "3.0.0"
  gem "rubyzip", "~> 2.3.2"
  gem "simplecov", "= 0.21.2"

  # rubocop
  unless RUBY_PLATFORM == "java"
    gem "standard", "1.43.0"
    gem "rubocop-minitest", "0.36.0"
    gem "rubocop-packaging", "0.5.2"
    gem "rubocop-rake", "0.6.0"
  end
end

# If Psych doesn't build, you can disable this group locally by running
# `bundle config set --local without rdoc`
# Then re-run `bundle install`.
group :rdoc do
  gem "rdoc", "6.10.0" unless RUBY_PLATFORM == "java" || ENV["CI"]
end
