# -*- encoding: utf-8 -*-
# stub: rack-proxy 0.7.7 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-proxy".freeze
  s.version = "0.7.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jacek Becela".freeze]
  s.date = "2023-09-01"
  s.description = "A Rack app that provides request/response rewriting proxy capabilities with streaming.".freeze
  s.email = ["jacek.becela@gmail.com".freeze]
  s.homepage = "https://github.com/ncr/rack-proxy".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6".freeze)
  s.rubygems_version = "3.2.3".freeze
  s.summary = "A request/response rewriting HTTP proxy. A Rack app.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 0".freeze])
end
