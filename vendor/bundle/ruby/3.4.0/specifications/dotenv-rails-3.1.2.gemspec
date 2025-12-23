# -*- encoding: utf-8 -*-
# stub: dotenv-rails 3.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "dotenv-rails".freeze
  s.version = "3.1.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brandon Keepers".freeze]
  s.date = "2024-05-06"
  s.description = "Autoload dotenv in Rails.".freeze
  s.email = ["brandon@opensoul.org".freeze]
  s.homepage = "https://github.com/bkeepers/dotenv".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.5.9".freeze
  s.summary = "Autoload dotenv in Rails.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<dotenv>.freeze, ["= 3.1.2".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 6.1".freeze])
  s.add_development_dependency(%q<spring>.freeze, [">= 0".freeze])
end
