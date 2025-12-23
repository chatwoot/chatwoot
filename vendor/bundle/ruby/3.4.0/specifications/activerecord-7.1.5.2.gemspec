# -*- encoding: utf-8 -*-
# stub: activerecord 7.1.5.2 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord".freeze
  s.version = "7.1.5.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/rails/rails/issues", "changelog_uri" => "https://github.com/rails/rails/blob/v7.1.5.2/activerecord/CHANGELOG.md", "documentation_uri" => "https://api.rubyonrails.org/v7.1.5.2/", "mailing_list_uri" => "https://discuss.rubyonrails.org/c/rubyonrails-talk", "rubygems_mfa_required" => "true", "source_code_uri" => "https://github.com/rails/rails/tree/v7.1.5.2/activerecord" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["David Heinemeier Hansson".freeze]
  s.date = "1980-01-02"
  s.description = "Databases on Rails. Build a persistent domain model by mapping database tables to Ruby classes. Strong conventions for associations, validations, aggregations, migrations, and testing come baked-in.".freeze
  s.email = "david@loudthinking.com".freeze
  s.extra_rdoc_files = ["README.rdoc".freeze]
  s.files = ["README.rdoc".freeze]
  s.homepage = "https://rubyonrails.org".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.6.9".freeze
  s.summary = "Object-relational mapper framework (part of Rails).".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["= 7.1.5.2".freeze])
  s.add_runtime_dependency(%q<activemodel>.freeze, ["= 7.1.5.2".freeze])
  s.add_runtime_dependency(%q<timeout>.freeze, [">= 0.4.0".freeze])
end
