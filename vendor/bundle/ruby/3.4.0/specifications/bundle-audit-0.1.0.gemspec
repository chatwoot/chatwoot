# -*- encoding: utf-8 -*-
# stub: bundle-audit 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "bundle-audit".freeze
  s.version = "0.1.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Stewart McKee".freeze]
  s.bindir = "exe".freeze
  s.date = "2017-06-30"
  s.description = "Just requires bundler-audit, if you've mistakenly required bundle-audit".freeze
  s.email = ["stewart@theizone.co.uk".freeze]
  s.homepage = "http://github.com/stewartmckee/bundle-audit".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "2.6.12".freeze
  s.summary = "Helper gem to require bundler-audit".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<bundler-audit>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, ["~> 1.15".freeze])
end
