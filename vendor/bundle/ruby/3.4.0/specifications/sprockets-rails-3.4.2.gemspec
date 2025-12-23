# -*- encoding: utf-8 -*-
# stub: sprockets-rails 3.4.2 ruby lib

Gem::Specification.new do |s|
  s.name = "sprockets-rails".freeze
  s.version = "3.4.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joshua Peek".freeze]
  s.date = "2021-12-11"
  s.email = "josh@joshpeek.com".freeze
  s.homepage = "https://github.com/rails/sprockets-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.2.32".freeze
  s.summary = "Sprockets Rails integration".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<sprockets>.freeze, [">= 3.0.0".freeze])
  s.add_runtime_dependency(%q<actionpack>.freeze, [">= 5.2".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.2".freeze])
  s.add_development_dependency(%q<railties>.freeze, [">= 5.2".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sass>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<uglifier>.freeze, [">= 0".freeze])
end
