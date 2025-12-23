# -*- encoding: utf-8 -*-
# stub: ruby_llm-schema 0.2.5 ruby lib

Gem::Specification.new do |s|
  s.name = "ruby_llm-schema".freeze
  s.version = "0.2.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/danielfriis/ruby_llm-schema/blob/main/CHANGELOG.md", "homepage_uri" => "https://github.com/danielfriis/ruby_llm-schema", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/danielfriis/ruby_llm-schema" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Daniel Friis".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-11-12"
  s.email = ["d@friis.me".freeze]
  s.homepage = "https://github.com/danielfriis/ruby_llm-schema".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.1.0".freeze)
  s.rubygems_version = "3.4.19".freeze
  s.summary = "A simple and clean Ruby DSL for creating JSON schemas.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0".freeze])
  s.add_development_dependency(%q<standard>.freeze, [">= 0".freeze])
end
