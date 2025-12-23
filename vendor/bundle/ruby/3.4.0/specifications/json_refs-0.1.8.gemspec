# -*- encoding: utf-8 -*-
# stub: json_refs 0.1.8 ruby lib

Gem::Specification.new do |s|
  s.name = "json_refs".freeze
  s.version = "0.1.8".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Makoto Tajitsu".freeze]
  s.bindir = "exe".freeze
  s.date = "2023-04-28"
  s.description = "Dereference JSON Pointer".freeze
  s.email = ["makoto_tajitsu@hotmail.co.jp".freeze]
  s.homepage = "https://github.com/tzmfreedom/json_refs".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.2.31".freeze
  s.summary = "Dereference JSON Pointer".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<hana>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 10.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
end
