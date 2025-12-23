# -*- encoding: utf-8 -*-
# stub: maxminddb 0.1.22 ruby lib

Gem::Specification.new do |s|
  s.name = "maxminddb".freeze
  s.version = "0.1.22".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["yhirose".freeze]
  s.date = "2018-09-15"
  s.description = "Pure Ruby MaxMind DB (GeoIP2) binary file reader.".freeze
  s.email = ["yuji.hirose.bug@gmail.com".freeze]
  s.homepage = "https://github.com/yhirose/maxminddb".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.8".freeze
  s.summary = "MaxMind DB binary file reader.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.5".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec-its>.freeze, [">= 0".freeze])
end
