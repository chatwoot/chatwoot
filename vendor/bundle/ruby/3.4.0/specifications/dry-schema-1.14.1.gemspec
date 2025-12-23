# -*- encoding: utf-8 -*-
# stub: dry-schema 1.14.1 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-schema".freeze
  s.version = "1.14.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-schema/issues", "changelog_uri" => "https://github.com/dry-rb/dry-schema/blob/main/CHANGELOG.md", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/dry-rb/dry-schema" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Solnica".freeze]
  s.date = "2025-03-03"
  s.description = "dry-schema provides a DSL for defining schemas with keys and rules that should be applied to\nvalues. It supports coercion, input sanitization, custom types and localized error messages\n(with or without I18n gem). It's also used as the schema engine in dry-validation.\n\n".freeze
  s.email = ["piotr.solnica@gmail.com".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-schema".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1".freeze)
  s.rubygems_version = "3.3.27".freeze
  s.summary = "Coercion and validation for data structures".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0".freeze])
  s.add_runtime_dependency(%q<dry-configurable>.freeze, ["~> 1.0".freeze, ">= 1.0.1".freeze])
  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<dry-initializer>.freeze, ["~> 3.2".freeze])
  s.add_runtime_dependency(%q<dry-logic>.freeze, ["~> 1.5".freeze])
  s.add_runtime_dependency(%q<dry-types>.freeze, ["~> 1.8".freeze])
  s.add_runtime_dependency(%q<zeitwerk>.freeze, ["~> 2.6".freeze])
end
