# -*- encoding: utf-8 -*-
# stub: crack 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "crack".freeze
  s.version = "1.0.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/jnunemaker/crack/issues", "changelog_uri" => "https://github.com/jnunemaker/crack/blob/master/History", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/jnunemaker/crack" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Nunemaker".freeze]
  s.date = "2024-02-09"
  s.description = "Really simple JSON and XML parsing, ripped from Merb and Rails.".freeze
  s.email = ["nunemaker@gmail.com".freeze]
  s.homepage = "https://github.com/jnunemaker/crack".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Really simple JSON and XML parsing, ripped from Merb and Rails.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<rexml>.freeze, [">= 0".freeze])
end
