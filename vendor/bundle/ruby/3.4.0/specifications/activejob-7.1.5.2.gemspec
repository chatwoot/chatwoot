# -*- encoding: utf-8 -*-
# stub: activejob 7.1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "activejob".freeze
  s.version = "7.1.5.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v7.1.5.2/activejob/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v7.1.5.2/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.1.5.2/activejob" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "1980-01-02"
  s.description = "Declare job classes that can be run by a variety of queuing backends.".freeze
  s.email = "david@loudthinking.com".freeze
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Job framework with pluggable queues.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.1.5.2".freeze])
  s.add_runtime_dependency(%q<globalid>.freeze, [">= 0.3.6".freeze])
end
