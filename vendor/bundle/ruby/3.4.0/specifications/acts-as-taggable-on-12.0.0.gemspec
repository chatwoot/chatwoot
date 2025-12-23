# -*- encoding: utf-8 -*-
# stub: acts-as-taggable-on 12.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "acts-as-taggable-on".freeze
  s.version = "12.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Bleigh".freeze, "Joost Baaij".freeze]
  s.date = "2024-11-09"
  s.description = "With ActsAsTaggableOn, you can tag a single model on several contexts, such as skills, interests, and awards. It also provides other advanced functionality.".freeze
  s.email = ["michael@intridea.com".freeze, "joost@spacebabies.nl".freeze]
  s.homepage = "https://github.com/mbleigh/acts-as-taggable-on".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2.0".freeze)
  s.rubygems_version = "3.5.6".freeze
  s.summary = "Advanced tagging for Rails.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 7.1".freeze, "< 8.1".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, [">= 2.4".freeze, "< 3.0".freeze])
  s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<barrier>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<database_cleaner>.freeze, [">= 0".freeze])
end
