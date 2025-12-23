source 'https://rubygems.org'

# Specify your gem's dependencies in child_process.gemspec
gemspec

# Used for local development/testing only
gem 'rake'

# Newer versions of term-ansicolor (used by coveralls) do not work on Ruby 2.4
gem 'term-ansicolor', '< 1.8.0' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.5')
