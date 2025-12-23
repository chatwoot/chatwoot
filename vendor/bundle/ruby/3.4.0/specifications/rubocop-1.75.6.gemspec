# -*- encoding: utf-8 -*-
# stub: rubocop 1.75.6 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop".freeze
  s.version = "1.75.6".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubocop/rubocop/issues", "changelog_uri" => "https://github.com/rubocop/rubocop/releases/tag/v1.75.6", "documentation_uri" => "https://docs.rubocop.org/rubocop/1.75/", "homepage_uri" => "https://rubocop.org/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rubocop/rubocop/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bozhidar Batsov".freeze, "Jonas Arvidsson".freeze, "Yuji Nakayama".freeze]
  s.bindir = "exe".freeze
  s.date = "2025-05-15"
  s.description = "RuboCop is a Ruby code style checking and code formatting tool.\nIt aims to enforce the community-driven Ruby Style Guide.\n".freeze
  s.email = "rubocop@googlegroups.com".freeze
  s.executables = ["rubocop".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze, "exe/rubocop".freeze]
  s.homepage = "https://github.com/rubocop/rubocop".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "Automatic Ruby code style checking tool.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<json>.freeze, ["~> 2.3".freeze])
  s.add_runtime_dependency(%q<language_server-protocol>.freeze, ["~> 3.17.0.2".freeze])
  s.add_runtime_dependency(%q<lint_roller>.freeze, ["~> 1.1.0".freeze])
  s.add_runtime_dependency(%q<parallel>.freeze, ["~> 1.10".freeze])
  s.add_runtime_dependency(%q<parser>.freeze, [">= 3.3.0.2".freeze])
  s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.2.2".freeze, "< 4.0".freeze])
  s.add_runtime_dependency(%q<regexp_parser>.freeze, [">= 2.9.3".freeze, "< 3.0".freeze])
  s.add_runtime_dependency(%q<rubocop-ast>.freeze, [">= 1.44.0".freeze, "< 2.0".freeze])
  s.add_runtime_dependency(%q<ruby-progressbar>.freeze, ["~> 1.7".freeze])
  s.add_runtime_dependency(%q<unicode-display_width>.freeze, [">= 2.4.0".freeze, "< 4.0".freeze])
end
