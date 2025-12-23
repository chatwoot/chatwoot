# -*- encoding: utf-8 -*-
# stub: et-orbi 1.2.11 ruby lib

Gem::Specification.new do |s|
  s.name = "et-orbi".freeze
  s.version = "1.2.11".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/floraison/et-orbi/issues", "changelog_uri" => "https://github.com/floraison/et-orbi/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/floraison/et-orbi", "homepage_uri" => "https://github.com/floraison/et-orbi", "source_code_uri" => "https://github.com/floraison/et-orbi" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Mettraux".freeze]
  s.date = "2024-03-23"
  s.description = "Time zones for fugit and rufus-scheduler. Urbi et Orbi.".freeze
  s.email = ["jmettraux+flor@gmail.com".freeze]
  s.homepage = "https://github.com/floraison/et-orbi".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "time with zones".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<tzinfo>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8".freeze])
  s.add_development_dependency(%q<chronic>.freeze, ["~> 0.10".freeze])
end
