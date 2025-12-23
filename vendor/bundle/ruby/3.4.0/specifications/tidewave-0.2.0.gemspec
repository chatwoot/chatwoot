# -*- encoding: utf-8 -*-
# stub: tidewave 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "tidewave".freeze
  s.version = "0.2.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/tidewave-ai/tidewave_rails/blob/main/CHANGELOG.md", "homepage_uri" => "https://tidewave.ai/", "source_code_uri" => "https://github.com/tidewave-ai/tidewave_rails" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yorick Jacquin".freeze]
  s.date = "2025-08-12"
  s.description = "Tidewave for Rails".freeze
  s.email = ["support@tidewave.ai".freeze]
  s.homepage = "https://tidewave.ai/".freeze
  s.licenses = ["Apache-2.0".freeze]
  s.rubygems_version = "3.4.1".freeze
  s.summary = "Tidewave for Rails".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<rails>.freeze, [">= 7.1.0".freeze])
  s.add_runtime_dependency(%q<fast-mcp>.freeze, ["~> 1.5.0".freeze])
  s.add_runtime_dependency(%q<rack>.freeze, [">= 2.0".freeze])
end
