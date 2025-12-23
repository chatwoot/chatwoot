# -*- encoding: utf-8 -*-
# stub: uri_template 0.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "uri_template".freeze
  s.version = "0.7.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["HannesG".freeze]
  s.date = "2014-03-21"
  s.description = "A templating system for URIs, which implements RFC6570 and Colon based URITemplates in a clean and straight forward way.".freeze
  s.email = "hannes.georg@googlemail.com".freeze
  s.homepage = "http://github.com/hannesg/uri_template".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.2.1".freeze
  s.summary = "A templating system for URIs.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<multi_json>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 0".freeze])
end
