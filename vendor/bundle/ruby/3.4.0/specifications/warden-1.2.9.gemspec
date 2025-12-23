# -*- encoding: utf-8 -*-
# stub: warden 1.2.9 ruby lib

Gem::Specification.new do |s|
  s.name = "warden".freeze
  s.version = "1.2.9".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Neighman".freeze, "Justin Smestad".freeze, "Whitney Smestad".freeze, "Jos\u00E9 Valim".freeze]
  s.date = "2020-08-31"
  s.email = "hasox.sox@gmail.com justin.smestad@gmail.com whitcolorado@gmail.com".freeze
  s.extra_rdoc_files = ["LICENSE".freeze, "README.md".freeze]
  s.files = ["LICENSE".freeze, "README.md".freeze]
  s.homepage = "https://github.com/hassox/warden".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "An authentication library compatible with all Rack-based frameworks".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.0.9".freeze])
end
