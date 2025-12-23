# -*- encoding: utf-8 -*-
# stub: factory_bot 6.4.5 ruby lib

Gem::Specification.new do |s|
  s.name = "factory_bot".freeze
  s.version = "6.4.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/thoughtbot/factory_bot/blob/main/NEWS.md" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josh Clayton".freeze, "Joe Ferris".freeze]
  s.date = "2023-12-30"
  s.description = "factory_bot provides a framework and DSL for defining and using factories - less error-prone, more explicit, and all-around easier to work with than fixtures.".freeze
  s.email = ["jclayton@thoughtbot.com".freeze, "jferris@thoughtbot.com".freeze]
  s.homepage = "https://github.com/thoughtbot/factory_bot".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "factory_bot provides a framework and DSL for defining and using model instance factories.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0.0".freeze])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<aruba>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<cucumber>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
end
