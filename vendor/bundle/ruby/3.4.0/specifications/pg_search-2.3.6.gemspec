# -*- encoding: utf-8 -*-
# stub: pg_search 2.3.6 ruby lib

Gem::Specification.new do |s|
  s.name = "pg_search".freeze
  s.version = "2.3.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Grant Hutchins".freeze, "Case Commons, LLC".freeze]
  s.date = "2022-01-07"
  s.description = "PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search".freeze
  s.email = ["gems@nertzy.com".freeze, "casecommons-dev@googlegroups.com".freeze]
  s.homepage = "https://github.com/Casecommons/pg_search".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.3.3".freeze
  s.summary = "PgSearch builds Active Record named scopes that take advantage of PostgreSQL's full text search".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-performance>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rubocop-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov-lcov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<undercover>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<warning>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<with_model>.freeze, [">= 0".freeze])
end
