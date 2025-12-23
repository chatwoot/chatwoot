# -*- encoding: utf-8 -*-
# stub: dry-types 1.8.3 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-types".freeze
  s.version = "1.8.3".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-types/issues", "changelog_uri" => "https://github.com/dry-rb/dry-types/blob/main/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/dry-rb/dry-types" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Solnica".freeze]
  s.date = "2025-06-09"
  s.description = "Type system for Ruby supporting coercions, constraints and complex types like structs, value objects, enums etc".freeze
  s.email = ["piotr.solnica@gmail.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-types".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Type system for Ruby supporting coercions, constraints and complex types like structs, value objects, enums etc".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<bigdecimal>.freeze, ["~> 3.0".freeze])
  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<dry-inflector>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<dry-logic>.freeze, ["~> 1.4".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6".freeze])
end
