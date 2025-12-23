# -*- encoding: utf-8 -*-
# stub: representable 3.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "representable".freeze
  s.version = "3.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Sutterer".freeze]
  s.date = "2022-05-16"
  s.description = "Renders and parses JSON/XML/YAML documents from and to Ruby objects. Includes plain properties, collections, nesting, coercion and more.".freeze
  s.email = ["apotonick@gmail.com".freeze]
  s.homepage = "https://github.com/trailblazer/representable/".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)
  s.rubygems_version = "3.0.3.1".freeze
  s.summary = "Renders and parses JSON/XML/YAML documents from and to Ruby objects. Includes plain properties, collections, nesting, coercion and more.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<uber>.freeze, ["< 0.2.0".freeze])
  s.add_runtime_dependency(%q<declarative>.freeze, ["< 0.1.0".freeze])
  s.add_runtime_dependency(%q<trailblazer-option>.freeze, [">= 0.1.1".freeze, "< 0.2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<test_xml>.freeze, [">= 0.1.6".freeze])
  s.add_development_dependency(%q<minitest>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<virtus>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<dry-types>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<ruby-prof>.freeze, [">= 0".freeze])
end
