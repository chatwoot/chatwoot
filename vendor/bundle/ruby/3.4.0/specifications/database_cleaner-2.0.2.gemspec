# -*- encoding: utf-8 -*-
# stub: database_cleaner 2.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "database_cleaner".freeze
  s.version = "2.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/DatabaseCleaner/database_cleaner/blob/master/History.rdoc" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ben Mabey".freeze, "Ernesto Tagwerker".freeze, "Micah Geisel".freeze]
  s.date = "2023-03-10"
  s.description = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing.".freeze
  s.email = ["ernesto@ombulabs.com".freeze]
  s.homepage = "https://github.com/DatabaseCleaner/database_cleaner".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Strategies for cleaning databases. Can be used to ensure a clean slate for testing.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<database_cleaner-active_record>.freeze, [">= 2".freeze, "< 3".freeze])
end
