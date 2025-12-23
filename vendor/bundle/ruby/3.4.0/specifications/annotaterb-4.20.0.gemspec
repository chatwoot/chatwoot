# -*- encoding: utf-8 -*-
# stub: annotaterb 4.20.0 ruby lib

Gem::Specification.new do |s|
  s.name = "annotaterb".freeze
  s.version = "4.20.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/drwl/annotaterb/issues", "changelog_uri" => "https://github.com/drwl/annotaterb/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/drwl/annotaterb", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/drwl/annotaterb" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Andrew W. Lee".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-10-20"
  s.description = "Annotates Rails/ActiveRecord Models, routes, fixtures, and others based on the database schema.".freeze
  s.email = ["git@drewlee.com".freeze]
  s.executables = ["annotaterb".freeze]
  s.files = ["exe/annotaterb".freeze]
  s.homepage = "https://github.com/drwl/annotaterb".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0.0".freeze)
  s.rubygems_version = "3.5.22".freeze
  s.summary = "A gem for generating annotations for Rails projects.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activerecord>.freeze, [">= 6.0.0".freeze])
  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 6.0.0".freeze])
end
