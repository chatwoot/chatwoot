# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'pg_search/version'

Gem::Specification.new do |s| # rubocop:disable Metrics/BlockLength
  s.name        = 'pg_search'
  s.version     = PgSearch::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Grant Hutchins', 'Case Commons, LLC']
  s.email       = %w[gems@nertzy.com casecommons-dev@googlegroups.com]
  s.homepage    = 'https://github.com/Casecommons/pg_search'
  s.summary     = "PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search"
  s.description = "PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search"
  s.licenses    = ['MIT']
  s.metadata["rubygems_mfa_required"] = "true"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency 'activerecord', '>= 5.2'
  s.add_dependency 'activesupport', '>= 5.2'

  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-performance'
  s.add_development_dependency 'rubocop-rails'
  s.add_development_dependency 'rubocop-rake'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-lcov'
  s.add_development_dependency 'undercover'
  s.add_development_dependency 'warning'
  s.add_development_dependency 'with_model'

  s.required_ruby_version = '>= 2.6'
end
