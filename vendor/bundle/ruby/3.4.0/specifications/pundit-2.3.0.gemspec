# -*- encoding: utf-8 -*-
# stub: pundit 2.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pundit".freeze
  s.version = "2.3.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jonas Nicklas".freeze, "Varvet AB".freeze]
  s.date = "2022-12-19"
  s.description = "Object oriented authorization for Rails applications".freeze
  s.email = ["jonas.nicklas@gmail.com".freeze, "dev@elabs.se".freeze]
  s.homepage = "https://github.com/varvet/pundit".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.3.7".freeze
  s.summary = "OO authorization for Rails".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<actionpack>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<activemodel>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<pry>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<railties>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 1.24.0".freeze])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0.17.0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
end
