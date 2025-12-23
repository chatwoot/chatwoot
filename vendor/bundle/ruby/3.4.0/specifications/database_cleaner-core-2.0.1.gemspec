# -*- encoding: utf-8 -*-
# stub: database_cleaner-core 2.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "database_cleaner-core".freeze
  s.version = "2.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben Mabey".freeze, "Ernesto Tagwerker".freeze]
  s.bindir = "exe".freeze
  s.date = "2021-02-04"
  s.description = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing.".freeze
  s.email = ["ernesto@ombulabs.com".freeze]
  s.homepage = "https://github.com/DatabaseCleaner/database_cleaner".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<listen>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<cucumber>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<database_cleaner-active_record>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<database_cleaner-redis>.freeze, [">= 0".freeze])
end
