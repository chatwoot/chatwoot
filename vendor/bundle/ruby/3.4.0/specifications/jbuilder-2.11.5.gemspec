# -*- encoding: utf-8 -*-
# stub: jbuilder 2.11.5 ruby lib

Gem::Specification.new do |s|
  s.name = "jbuilder".freeze
  s.version = "2.11.5".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/jbuilder/issues", "changelog_uri" => "https://github.com/rails/jbuilder/releases/tag/v2.11.5", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/jbuilder/tree/v2.11.5" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "2021-12-21"
  s.email = "david@basecamp.com".freeze
  s.homepage = "https://github.com/rails/jbuilder".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.2".freeze)
  s.rubygems_version = "3.2.32".freeze
  s.summary = "Create JSON structures via a Builder-style DSL".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, [">= 5.0.0".freeze])
  s.add_runtime_dependency(%q<actionview>.freeze, [">= 5.0.0".freeze])
end
