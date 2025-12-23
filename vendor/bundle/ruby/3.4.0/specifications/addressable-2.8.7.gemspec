# -*- encoding: utf-8 -*-
# stub: addressable 2.8.7 ruby lib

Gem::Specification.new do |s|
  s.name = "addressable".freeze
  s.version = "2.8.7".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/sporkmonger/addressable/blob/main/CHANGELOG.md#v2.8.7" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bob Aman".freeze]
  s.date = "2024-06-21"
  s.description = "Addressable is an alternative implementation to the URI implementation that is\npart of Ruby's standard library. It is flexible, offers heuristic parsing, and\nadditionally provides extensive support for IRIs and URI templates.\n".freeze
  s.email = "bob@sporkmonger.com".freeze
  s.extra_rdoc_files = ["README.md".freeze]
  s.files = ["README.md".freeze]
  s.homepage = "https://github.com/sporkmonger/addressable".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.5.11".freeze
  s.summary = "URI Implementation".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<public_suffix>.freeze, [">= 2.0.2".freeze, "< 7.0".freeze])
  s.add_development_dependency(%q<bundler>.freeze, [">= 1.0".freeze, "< 3.0".freeze])
end
