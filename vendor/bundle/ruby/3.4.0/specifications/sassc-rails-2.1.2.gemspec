# -*- encoding: utf-8 -*-
# stub: sassc-rails 2.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "sassc-rails".freeze
  s.version = "2.1.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Ryan Boland".freeze]
  s.date = "2019-06-18"
  s.description = "Integrate SassC-Ruby into Rails.".freeze
  s.email = ["ryan@tanookilabs.com".freeze]
  s.homepage = "https://github.com/sass/sassc-rails".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.7.6".freeze
  s.summary = "Integrate SassC-Ruby into Rails.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 10.0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<sassc>.freeze, [">= 2.0".freeze])
  s.add_runtime_dependency(%q<tilt>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 4.0.0".freeze])
  s.add_runtime_dependency(%q<sprockets>.freeze, ["> 3.0".freeze])
  s.add_runtime_dependency(%q<sprockets-rails>.freeze, [">= 0".freeze])
end
