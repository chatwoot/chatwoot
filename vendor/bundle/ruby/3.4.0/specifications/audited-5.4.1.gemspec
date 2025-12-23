# -*- encoding: utf-8 -*-
# stub: audited 5.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "audited".freeze
  s.version = "5.4.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brandon Keepers".freeze, "Kenneth Kalmer".freeze, "Daniel Morrison".freeze, "Brian Ryckbost".freeze, "Steve Richert".freeze, "Ryan Glover".freeze]
  s.date = "2023-11-06"
  s.description = "Log all changes to your models".freeze
  s.email = "info@collectiveidea.com".freeze
  s.homepage = "https://github.com/collectiveidea/audited".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.4.7".freeze
  s.summary = "Log all changes to your models".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 5.0".freeze, "< 7.7".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0".freeze, "< 7.7".freeze])
  s.add_development_dependency(%q<appraisal>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rails>.freeze, [">= 5.0".freeze, "< 7.7".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<single_cov>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<sqlite3>.freeze, [">= 1.3.6".freeze])
  s.add_development_dependency(%q<mysql2>.freeze, [">= 0.3.20".freeze])
  s.add_development_dependency(%q<pg>.freeze, [">= 0.18".freeze, "< 2.0".freeze])
end
