# -*- encoding: utf-8 -*-
# stub: administrate-field-belongs_to_search 0.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "administrate-field-belongs_to_search".freeze
  s.version = "0.9.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Fishbrain".freeze]
  s.date = "2023-12-28"
  s.description = "  Add support to search through (potentially large) belongs_to associations in your Administrate dashboards.\n".freeze
  s.email = ["support@fishbrain.com".freeze]
  s.homepage = "https://github.com/fishbrain/administrate-field-belongs_to_search".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.6".freeze
  s.summary = "Plugin that adds search capabilities to belongs_to associations for Administrate".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<administrate>.freeze, [">= 0.3".freeze, "< 1.0".freeze])
  s.add_runtime_dependency(%q<jbuilder>.freeze, ["~> 2".freeze])
  s.add_runtime_dependency(%q<rails>.freeze, [">= 4.2".freeze, "< 7.2".freeze])
  s.add_runtime_dependency(%q<selectize-rails>.freeze, ["~> 0.6".freeze])
  s.add_development_dependency(%q<coveralls>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<factory_girl>.freeze, ["~> 4.8".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.4".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.76.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, ["~> 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, ["~> 1.3".freeze])
end
