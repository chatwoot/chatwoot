# -*- encoding: utf-8 -*-
# stub: rack-cors 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-cors".freeze
  s.version = "2.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Calvin Yu".freeze]
  s.date = "2023-02-14"
  s.description = "Middleware that will make Rack-based apps CORS compatible. Fork the project here: https://github.com/cyu/rack-cors".freeze
  s.email = ["me@sourcebender.com".freeze]
  s.homepage = "https://github.com/cyu/rack-cors".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Middleware for enabling Cross-Origin Resource Sharing in Rack apps".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.0.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.16.0".freeze, "< 3".freeze])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.11.0".freeze])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.6.0".freeze])
  s.add_development_dependency(%q<pry>.freeze, ["~> 0.12".freeze])
  s.add_development_dependency(%q<rack-test>.freeze, ["~> 1.1.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 12.3.0".freeze])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.80.1".freeze])
end
