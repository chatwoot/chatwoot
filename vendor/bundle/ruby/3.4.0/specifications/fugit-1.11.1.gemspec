# -*- encoding: utf-8 -*-
# stub: fugit 1.11.1 ruby lib

Gem::Specification.new do |s|
  s.name = "fugit".freeze
  s.version = "1.11.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/floraison/fugit/issues", "changelog_uri" => "https://github.com/floraison/fugit/blob/master/CHANGELOG.md", "documentation_uri" => "https://github.com/floraison/fugit", "homepage_uri" => "https://github.com/floraison/fugit", "source_code_uri" => "https://github.com/floraison/fugit" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Mettraux".freeze]
  s.date = "2024-08-15"
  s.description = "Time tools for flor and the floraison project. Cron parsing and occurrence computing. Timestamps and more.".freeze
  s.email = ["jmettraux+flor@gmail.com".freeze]
  s.homepage = "https://github.com/floraison/fugit".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "time tools for flor".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<raabro>.freeze, ["~> 1.4".freeze])
  s.add_runtime_dependency(%q<et-orbi>.freeze, ["~> 1".freeze, ">= 1.2.11".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.8".freeze])
  s.add_development_dependency(%q<chronic>.freeze, ["~> 0.10".freeze])
end
