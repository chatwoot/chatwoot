# -*- encoding: utf-8 -*-
# stub: simplecov 0.22.0 ruby lib

Gem::Specification.new do |s|
  s.name = "simplecov".freeze
  s.version = "0.22.0".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/simplecov-ruby/simplecov/issues", "changelog_uri" => "https://github.com/simplecov-ruby/simplecov/blob/main/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/simplecov/0.22.0", "mailing_list_uri" => "https://groups.google.com/forum/#!forum/simplecov", "source_code_uri" => "https://github.com/simplecov-ruby/simplecov/tree/v0.22.0" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Christoph Olszowka".freeze, "Tobias Pfeiffer".freeze]
  s.date = "2022-12-23"
  s.description = "Code coverage for Ruby with a powerful configuration library and automatic merging of coverage across test suites".freeze
  s.email = ["christoph at olszowka de".freeze, "pragtob@gmail.com".freeze]
  s.homepage = "https://github.com/simplecov-ruby/simplecov".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.3.7".freeze
  s.summary = "Code coverage for Ruby".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<docile>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<simplecov-html>.freeze, ["~> 0.11".freeze])
  s.add_runtime_dependency(%q<simplecov_json_formatter>.freeze, ["~> 0.1".freeze])
end
