# -*- encoding: utf-8 -*-
# stub: judoscale-rails 1.8.2 ruby lib

Gem::Specification.new do |s|
  s.name = "judoscale-rails".freeze
  s.version = "1.8.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/judoscale/judoscale-ruby/issues", "changelog_uri" => "https://github.com/judoscale/judoscale-ruby/blob/main/CHANGELOG.md", "documentation_uri" => "https://judoscale.com/docs", "homepage_uri" => "https://judoscale.com", "source_code_uri" => "https://github.com/judoscale/judoscale-ruby" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Adam McCrea".freeze, "Carlos Antonio da Silva".freeze, "Jon Sullivan".freeze]
  s.date = "2024-10-16"
  s.email = ["hello@judoscale.com".freeze]
  s.homepage = "https://judoscale.com".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.6.0".freeze)
  s.rubygems_version = "3.5.16".freeze
  s.summary = "Autoscaling for Ruby on Rails applications.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<judoscale-ruby>.freeze, ["= 1.8.2".freeze])
  s.add_runtime_dependency(%q<railties>.freeze, [">= 0".freeze])
end
