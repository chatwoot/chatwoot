# -*- encoding: utf-8 -*-
# stub: rubocop-ast 1.44.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-ast".freeze
  s.version = "1.44.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rubocop/rubocop-ast/issues", "changelog_uri" => "https://github.com/rubocop/rubocop-ast/blob/master/CHANGELOG.md", "documentation_uri" => "https://docs.rubocop.org/rubocop-ast/", "homepage_uri" => "https://www.rubocop.org/", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rubocop/rubocop-ast/" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bozhidar Batsov".freeze, "Jonas Arvidsson".freeze, "Yuji Nakayama".freeze]
  s.date = "2025-04-11"
  s.description = "    RuboCop's Node and NodePattern classes.\n".freeze
  s.email = "rubocop@googlegroups.com".freeze
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/rubocop/rubocop-ast".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.5.11".freeze
  s.summary = "RuboCop tools to deal with Ruby code AST.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<parser>.freeze, [">= 3.3.7.2".freeze])
  s.add_runtime_dependency(%q<prism>.freeze, ["~> 1.4".freeze])
end
